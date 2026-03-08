import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/repositories/auth_repository.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../gamification/presentation/cubit/gamification_cubit.dart';
import '../../../gamification/presentation/cubit/gamification_state.dart';
import '../../../gamification/presentation/screens/gamification_profile_screen.dart';
import '../bloc/load_status.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_section.dart';
import '../bloc/profile_state.dart';
import '../widgets/edit_preferences_sheet.dart';
import '../widgets/profile_character_card.dart';
import '../../data/models/user_preferences.dart';

/// MOB-9 / MOB-10: Profile hub screen.
///
/// Triggers [GamificationCubit.fetchProfile] on first open so the
/// character card populates immediately without visiting Gamification screen.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<GamificationCubit>();
      final currentState = cubit.state;
      final stateName = currentState.runtimeType.toString();

      if (currentState is GamificationLoaded ||
          currentState is GamificationLoading) {
        log('[GAM_UI] ProfileScreen opened — SKIP_FETCH state=$stateName');
      } else {
        log('[GAM_UI] ProfileScreen opened — TRIGGERING_FETCH state=$stateName');
        cubit.fetchProfile();
      }

      if (!mounted) return;
      context.read<ProfileBloc>().add(const ProfileStarted());
    });
  }

  void _openEditPreferencesSheet(BuildContext context, UserPreferences initialPrefs) {
    final profileBloc = context.read<ProfileBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: profileBloc,
        child: EditPreferencesSheet(initialPrefs: initialPrefs),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (prev, curr) => prev.preferencesUpdateError != curr.preferencesUpdateError,
      listener: (context, state) {
        final error = state.preferencesUpdateError;
        if (error != null && error.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
          context.read<ProfileBloc>().add(const PreferencesUpdateErrorDismissed());
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ProfileHeaderSection(),

              const SizedBox(height: 16),

              // ─── Task 2: minimal profile bloc proof (displayName/email, loading, error) ───
              BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, state) {
                  if (state.profileStatus == LoadStatus.loading &&
                      state.profile == null) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Loading profile…', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    );
                  }
                  if (state.profileStatus == LoadStatus.failure) {
                    final msg = state.errorFor(ProfileSection.profile) ?? 'Error';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Profile: $msg',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFB00020),
                        ),
                      ),
                    );
                  }
                  if (state.profile != null) {
                    final p = state.profile!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '${p.displayName} · ${p.email}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 16),

              // ─── Travel Preferences ───
              _TravelPreferencesCard(
                onEditPreferences: (initial) => _openEditPreferencesSheet(context, initial),
              ),
              const SizedBox(height: 16),

              // ─── Travel Statistics ───
              const _TravelStatisticsCard(),
              const SizedBox(height: 16),

              // ─── Check-in History ───
              const _CheckInHistoryCard(),
              const SizedBox(height: 16),

              // ─── Account actions ───
              BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, state) {
                  return _AccountActionsSection(
                    onEditPreferences: () {
                      final initial = state.preferences ??
                          UserPreferences.defaultForDraft(
                            userId: state.profile?.userId ?? '',
                          );
                      _openEditPreferencesSheet(context, initial);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

// ─── Header + Character + Gamification (isolated from ProfileBloc rebuilds) ───

class _ProfileHeaderSection extends StatelessWidget {
  const _ProfileHeaderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.chevron_left, size: 28),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        BlocBuilder<GamificationCubit, GamificationState>(
          buildWhen: (prev, curr) {
            if (prev.runtimeType != curr.runtimeType) return true;
            if (prev is GamificationLoaded && curr is GamificationLoaded) {
              return prev.profile != curr.profile;
            }
            return false;
          },
          builder: (context, state) {
            return switch (state) {
              GamificationInitial() || GamificationLoading() =>
                const ProfileCharacterCard(
                  name: 'Serhat',
                  roleText: '—',
                  levelText: '—',
                ),
              GamificationError() => const ProfileCharacterCard(
                  name: 'Serhat',
                  roleText: 'Traveler',
                  levelText: '—',
                ),
              GamificationLoaded(:final profile) => ProfileCharacterCard(
                  name: 'Serhat',
                  roleText: profile.roleText,
                  levelText: profile.levelText,
                  totalXp: profile.totalXp,
                  xpProgressPercent: profile.xpProgressPercent,
                ),
            };
          },
        ),
        const SizedBox(height: 24),
        _GamificationEntryTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const GamificationProfileScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Section card style (matches _GamificationEntryTile)
// ──────────────────────────────────────────────────────────────────

BoxDecoration _sectionCardDecoration() {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: 0.8),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

String _formatDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
}

// ──────────────────────────────────────────────────────────────────

class _TravelPreferencesCard extends StatelessWidget {
  final void Function(UserPreferences initialPrefs) onEditPreferences;

  const _TravelPreferencesCard({required this.onEditPreferences});

  void _openSheet(BuildContext context, ProfileState state) {
    final initial = state.preferences ??
        UserPreferences.defaultForDraft(userId: state.profile?.userId ?? '');
    onEditPreferences(initial);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (prev, curr) =>
          prev.preferencesStatus != curr.preferencesStatus ||
          prev.preferences != curr.preferences,
      builder: (context, state) {
        Widget cardChild;
        if (state.preferencesStatus == LoadStatus.loading &&
            state.preferences == null) {
          cardChild = const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Loading…', style: TextStyle(fontSize: 14)),
                ],
              ),
            );
        } else if (state.preferencesStatus == LoadStatus.failure) {
          final rawMsg = state.errorFor(ProfileSection.preferences) ?? 'Error';
          final is404 = rawMsg.contains('404');
          final msg = is404
              ? 'Preferences not available yet. Tap to set your preferences anyway.'
              : rawMsg;
          cardChild = Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(
                  is404 ? Icons.info_outline : Icons.error_outline,
                  size: 20,
                  color: is404 ? const Color(0xFF5F7A8F) : const Color(0xFFB00020),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    msg,
                    style: TextStyle(
                      fontSize: 14,
                      color: is404 ? const Color(0xFF5F7A8F) : const Color(0xFFB00020),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.read<ProfileBloc>().add(
                        ProfileSectionRetryRequested(ProfileSection.preferences),
                      ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else {
          final prefs = state.preferences;
          if (prefs == null || prefs.favoriteCategories.isEmpty) {
            final fallback = prefs?.travelStyle ?? prefs?.activityLevel;
            cardChild = Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                fallback != null ? _capitalize(fallback.replaceAll('_', ' ')) : 'No preferences set',
                style: const TextStyle(fontSize: 14, color: Color(0xFF5F7A8F)),
              ),
            );
          } else {
            final categories = prefs.favoriteCategories;
            const maxChips = 3;
            final show = categories.take(maxChips).toList();
            final extra = categories.length > maxChips ? categories.length - maxChips : 0;
            cardChild = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...show.map((c) => Chip(
                      label: Text(_capitalize(c)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    )),
                if (extra > 0)
                  Chip(
                    label: Text('+$extra'),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            );
          }
        }
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openSheet(context, state),
            borderRadius: BorderRadius.circular(20),
            child: _SectionCard(
              title: 'Travel Preferences',
              child: cardChild,
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────

class _TravelStatisticsCard extends StatelessWidget {
  const _TravelStatisticsCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (prev, curr) =>
          prev.statsStatus != curr.statsStatus || prev.stats != curr.stats,
      builder: (context, state) {
        if (state.statsStatus == LoadStatus.loading && state.stats == null) {
          return _SectionCard(
            title: 'Travel Statistics',
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Loading…', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          );
        }
        if (state.statsStatus == LoadStatus.failure) {
          final msg = state.errorFor(ProfileSection.stats) ?? 'Error';
          return _SectionCard(
            title: 'Travel Statistics',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 20, color: Color(0xFFB00020)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      msg,
                      style: const TextStyle(fontSize: 14, color: Color(0xFFB00020)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.read<ProfileBloc>().add(
                          ProfileSectionRetryRequested(ProfileSection.stats),
                        ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        final stats = state.stats;
        if (stats == null) return const SizedBox.shrink();
        if (stats.visitedPoisCount == 0) {
          return _SectionCard(
            title: 'Travel Statistics',
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No places visited yet. Complete a check-in to see stats.',
                style: TextStyle(fontSize: 14, color: Color(0xFF5F7A8F)),
              ),
            ),
          );
        }
        return _SectionCard(
          title: 'Travel Statistics',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Places visited: ${stats.visitedPoisCount}', style: _statStyle),
                if (stats.lastVisitPoiName != null && stats.lastVisitDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Last: ${stats.lastVisitPoiName}, ${_formatDate(stats.lastVisitDate!)}',
                      style: _statStyle,
                    ),
                  ),
                if (stats.favoriteCategory != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Favorite category: ${_capitalize(stats.favoriteCategory!)}', style: _statStyle),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Categories explored: ${stats.distinctCategoriesCount}', style: _statStyle),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

const TextStyle _statStyle = TextStyle(fontSize: 14, color: Color(0xFF2C3E50));

// ──────────────────────────────────────────────────────────────────

class _CheckInHistoryCard extends StatelessWidget {
  const _CheckInHistoryCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (prev, curr) =>
          prev.checkInsStatus != curr.checkInsStatus ||
          prev.checkIns != curr.checkIns,
      builder: (context, state) {
        if (state.checkInsStatus == LoadStatus.loading && state.checkIns.isEmpty) {
          return _SectionCard(
            title: 'Check-in History',
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Loading…', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          );
        }
        if (state.checkInsStatus == LoadStatus.failure) {
          final msg = state.errorFor(ProfileSection.checkIns) ?? 'Error';
          return _SectionCard(
            title: 'Check-in History',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 20, color: Color(0xFFB00020)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      msg,
                      style: const TextStyle(fontSize: 14, color: Color(0xFFB00020)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.read<ProfileBloc>().add(
                          ProfileSectionRetryRequested(ProfileSection.checkIns),
                        ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        final checkIns = state.checkIns;
        if (checkIns.isEmpty) {
          return _SectionCard(
            title: 'Check-in History',
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No check-ins yet. Your visits will appear here.',
                style: TextStyle(fontSize: 14, color: Color(0xFF5F7A8F)),
              ),
            ),
          );
        }
        const previewCount = 5;
        final preview = checkIns.take(previewCount).toList();
        return _SectionCard(
          title: 'Check-in History',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...preview.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${c.poiName} · ${_capitalize(c.category)} · ${_formatDate(c.checkedInAt)}',
                        style: _statStyle,
                      ),
                    )),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('See all — coming soon')),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────

class _AccountActionsSection extends StatelessWidget {
  final VoidCallback onEditPreferences;

  const _AccountActionsSection({required this.onEditPreferences});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Account',
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline, size: 22, color: Color(0xFF2C3E50)),
            title: const Text('Edit Profile', style: TextStyle(fontSize: 15)),
            trailing: const Icon(Icons.chevron_right, size: 22, color: Color(0xFFB0BEC5)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit Profile — coming in Task 5')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune, size: 22, color: Color(0xFF2C3E50)),
            title: const Text('Edit Preferences', style: TextStyle(fontSize: 15)),
            trailing: const Icon(Icons.chevron_right, size: 22, color: Color(0xFFB0BEC5)),
            onTap: onEditPreferences,
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, size: 22, color: Color(0xFF2C3E50)),
            title: const Text('Logout', style: TextStyle(fontSize: 15)),
            trailing: const Icon(Icons.chevron_right, size: 22, color: Color(0xFFB0BEC5)),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await context.read<AuthRepository>().logout();
    } finally {
      NavigationService.resetToLogin();
    }
  }
}

// ──────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _sectionCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────

class _GamificationEntryTile extends StatelessWidget {
  final VoidCallback onTap;

  const _GamificationEntryTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFD166), Color(0xFFF4A261)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD166).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.emoji_events,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gamification',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'XP, badges, and challenges',
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFF5F7A8F)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 22, color: Color(0xFFB0BEC5)),
            ],
          ),
        ),
      ),
    );
  }
}
