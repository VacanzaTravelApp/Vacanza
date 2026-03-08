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
import '../styles/profile_ui_style.dart';
import '../widgets/edit_preferences_sheet.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/profile_character_card.dart';
import '../../data/models/check_in.dart';
import '../../data/models/user_preferences.dart';
import '../../data/models/user_profile.dart';

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

  void _openEditProfileSheet(BuildContext context, UserProfile initialProfile) {
    final profileBloc = context.read<ProfileBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: profileBloc,
        child: EditProfileSheet(initialProfile: initialProfile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (prev, curr) =>
          prev.preferencesUpdateError != curr.preferencesUpdateError ||
          prev.profileUpdateError != curr.profileUpdateError,
      listener: (context, state) {
        final prefsError = state.preferencesUpdateError;
        if (prefsError != null && prefsError.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(prefsError)),
          );
          context.read<ProfileBloc>().add(const PreferencesUpdateErrorDismissed());
          return;
        }
        final profileError = state.profileUpdateError;
        if (profileError != null && profileError.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(profileError)),
          );
          context.read<ProfileBloc>().add(const ProfileUpdateErrorDismissed());
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
                    final name = p.displayName.trim().isNotEmpty
                        ? p.displayName
                        : p.displayNameFallback;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '$name · ${p.email}',
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
                    onEditProfile: () {
                      final initial = state.profile ??
                          UserProfile.defaultForDraft(
                            userId: state.profile?.userId ?? '',
                            email: state.profile?.email ?? '',
                          );
                      _openEditProfileSheet(context, initial);
                    },
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
        BlocBuilder<ProfileBloc, ProfileState>(
          buildWhen: (prev, curr) => prev.profile != curr.profile,
          builder: (context, profileState) {
            final displayName = profileState.profile != null
                ? (profileState.profile!.displayName.trim().isNotEmpty
                    ? profileState.profile!.displayName
                    : profileState.profile!.displayNameFallback)
                : '—';
            return BlocBuilder<GamificationCubit, GamificationState>(
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
                    ProfileCharacterCard(
                      name: displayName,
                      roleText: '—',
                      levelText: '—',
                    ),
                  GamificationError() => ProfileCharacterCard(
                      name: displayName,
                      roleText: 'Traveler',
                      levelText: '—',
                    ),
                  GamificationLoaded(:final profile) => ProfileCharacterCard(
                      name: displayName,
                      roleText: profile.roleText,
                      levelText: profile.levelText,
                      totalXp: profile.totalXp,
                      xpProgressPercent: profile.xpProgressPercent,
                    ),
                };
              },
            );
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
        if (state.preferencesStatus == LoadStatus.loading &&
            state.preferences == null) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openSheet(context, state),
              borderRadius: BorderRadius.circular(20),
              child: _SectionCard(
                title: 'Travel Preferences',
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
              ),
            ),
          );
        }
        if (state.preferencesStatus == LoadStatus.failure) {
          final rawMsg = state.errorFor(ProfileSection.preferences) ?? 'Error';
          final is404 = rawMsg.contains('404');
          final msg = is404
              ? 'Preferences not available yet. Tap to set your preferences anyway.'
              : rawMsg;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openSheet(context, state),
              borderRadius: BorderRadius.circular(20),
              child: _SectionCard(
                title: 'Travel Preferences',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        is404 ? Icons.info_outline : Icons.error_outline,
                        size: 20,
                        color: is404 ? ProfileUIColors.profileGray500 : const Color(0xFFB00020),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          msg,
                          style: TextStyle(
                            fontSize: 14,
                            color: is404 ? ProfileUIColors.profileGray500 : const Color(0xFFB00020),
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
                ),
              ),
            ),
          );
        }
        final prefs = state.preferences;
        if (prefs == null) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openSheet(context, state),
              borderRadius: BorderRadius.circular(20),
              child: _SectionCard(
                title: 'Travel Preferences',
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No preferences set',
                    style: TextStyle(fontSize: 14, color: ProfileUIColors.profileGray500),
                  ),
                ),
              ),
            ),
          );
        }
        // Row layout: icon + content + chevron
        const maxCats = 3;
        final categories = prefs.favoriteCategories;
        final showCats = categories.take(maxCats).toList();
        final extraCats = categories.length > maxCats ? categories.length - maxCats : 0;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openSheet(context, state),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: ProfileCardDecoration.card(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  profileIconContainer(
                    gradient: ProfileIconGradient.travelPrefs,
                    icon: const Icon(Icons.tune, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Travel Preferences',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ProfileUIColors.profileGray800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Personalize recommendations',
                          style: TextStyle(fontSize: 12, color: ProfileUIColors.profileGray500),
                        ),
                        const SizedBox(height: 12),
                        profileSummaryRow(
                          label: 'Travel style',
                          value: Text(
                            prefs.travelStyle != null
                                ? _capitalize(prefs.travelStyle!.replaceAll('_', ' '))
                                : '—',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: ProfileUIColors.profileGray800,
                            ),
                          ),
                        ),
                        profileSummaryRow(
                          label: 'Categories',
                          value: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              ...showCats.map((c) => ProfileChipStyle.categoryPill(_capitalize(c))),
                              if (extraCats > 0) ProfileChipStyle.extraPill('+$extraCats'),
                            ],
                          ),
                        ),
                        profileSummaryRow(
                          label: 'Daily budget',
                          value: Text(
                            '${prefs.dailyBudget ?? '—'} ${prefs.budgetCurrency ?? ''}'.trim(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: ProfileUIColors.profileGray800,
                            ),
                          ),
                        ),
                        if (prefs.dietaryRestrictions.isNotEmpty)
                          profileSummaryRow(
                            label: 'Dietary',
                            value: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: prefs.dietaryRestrictions
                                  .map((d) => ProfileChipStyle.dietaryPill(_capitalize(d)))
                                  .toList(),
                            ),
                          ),
                        profileSummaryRow(
                          label: 'Language',
                          value: Text(
                            (prefs.preferredLanguage ?? '—').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: ProfileUIColors.profileGray800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.chevron_right, size: 22, color: ProfileUIColors.profileGray400),
                  ),
                ],
              ),
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

  Widget _buildHeader() {
    return Row(
      children: [
        profileIconContainer(
          gradient: ProfileIconGradient.stats,
          icon: const Icon(Icons.bar_chart, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Travel Statistics',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ProfileUIColors.profileGray800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Your journey so far',
                style: TextStyle(fontSize: 12, color: ProfileUIColors.profileGray500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (prev, curr) =>
          prev.statsStatus != curr.statsStatus || prev.stats != curr.stats,
      builder: (context, state) {
        if (state.statsStatus == LoadStatus.loading && state.stats == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: ProfileCardDecoration.card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                const Row(
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
              ],
            ),
          );
        }
        if (state.statsStatus == LoadStatus.failure) {
          final msg = state.errorFor(ProfileSection.stats) ?? 'Error';
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: ProfileCardDecoration.card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                Row(
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
              ],
            ),
          );
        }
        final stats = state.stats;
        if (stats == null) return const SizedBox.shrink();
        if (stats.visitedPoisCount == 0) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: ProfileCardDecoration.card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No check-ins yet. Start exploring!',
                      style: TextStyle(fontSize: 14, color: ProfileUIColors.profileGray400),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: ProfileCardDecoration.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 12.0;
                  final tileWidth = (constraints.maxWidth - gap) / 2;
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: tileWidth,
                            child: profileStatTile(
                              title: Text('${stats.visitedPoisCount}'),
                              subtitle: 'Total places visited',
                            ),
                          ),
                          const SizedBox(width: gap),
                          SizedBox(
                            width: tileWidth,
                            child: profileStatTile(
                              title: Text(
                                stats.lastVisitPoiName ?? '—',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              subtitle: stats.lastVisitDate != null
                                  ? _formatDate(stats.lastVisitDate!)
                                  : 'Last visit',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: gap),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: tileWidth,
                            child: profileStatTile(
                              title: Text(_capitalize(stats.favoriteCategory ?? '—')),
                              subtitle: 'Favorite category',
                            ),
                          ),
                          const SizedBox(width: gap),
                          SizedBox(
                            width: tileWidth,
                            child: profileStatTile(
                              title: Text('${stats.distinctCategoriesCount}'),
                              subtitle: 'Categories explored',
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────

class _CheckInHistoryCard extends StatelessWidget {
  const _CheckInHistoryCard();

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        profileIconContainer(
          gradient: ProfileIconGradient.checkIn,
          icon: const Icon(Icons.schedule, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Check-in History',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ProfileUIColors.profileGray800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Places you've visited",
                style: TextStyle(fontSize: 12, color: ProfileUIColors.profileGray500),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('See all — coming soon')),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: ProfileUIColors.profileBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'See all',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckInRow(CheckIn c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ProfileUIColors.profileAmber.withValues(alpha: 0.15),
            ),
            child: Icon(
              Icons.place,
              size: 18,
              color: ProfileUIColors.profileOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.poiName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: ProfileUIColors.profileGray800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ProfileUIColors.profileGray100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.label_outline, size: 10, color: ProfileUIColors.profileGray500),
                          const SizedBox(width: 4),
                          Text(
                            _capitalize(c.category),
                            style: const TextStyle(
                              fontSize: 10,
                              color: ProfileUIColors.profileGray500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(c.checkedInAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: ProfileUIColors.profileGray400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: ProfileUIColors.profileGray400),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (prev, curr) =>
          prev.checkInsStatus != curr.checkInsStatus ||
          prev.checkIns != curr.checkIns,
      builder: (context, state) {
        if (state.checkInsStatus == LoadStatus.loading && state.checkIns.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: ProfileCardDecoration.card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                const Row(
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
              ],
            ),
          );
        }
        if (state.checkInsStatus == LoadStatus.failure) {
          final msg = state.errorFor(ProfileSection.checkIns) ?? 'Error';
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: ProfileCardDecoration.card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                Row(
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
              ],
            ),
          );
        }
        final checkIns = state.checkIns;
        if (checkIns.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: ProfileCardDecoration.card(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No check-ins yet. Start exploring!',
                      style: TextStyle(fontSize: 14, color: ProfileUIColors.profileGray400),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        const previewCount = 5;
        final preview = checkIns.take(previewCount).toList();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: ProfileCardDecoration.card(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              ...preview.asMap().entries.map((e) {
                final isLast = e.key == preview.length - 1;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCheckInRow(e.value),
                    if (!isLast)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: ProfileUIColors.profileGray100,
                      ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────

class _AccountActionsSection extends StatelessWidget {
  final VoidCallback onEditProfile;
  final VoidCallback onEditPreferences;

  const _AccountActionsSection({
    required this.onEditProfile,
    required this.onEditPreferences,
  });

  InkWell _accountRow({
    required BuildContext context,
    required VoidCallback onTap,
    required Widget iconContainer,
    required String title,
    required TextStyle titleStyle,
    required Color chevronColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            iconContainer,
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: titleStyle,
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: chevronColor),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: ProfileCardDecoration.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('ACCOUNT', style: profileSectionLabelStyle),
          ),
          _accountRow(
            context: context,
            onTap: onEditProfile,
            iconContainer: profileAccountIconContainer(
              backgroundColor: ProfileUIColors.profileBlue.withValues(alpha: 0.1),
              iconColor: ProfileUIColors.profileBlue,
              icon: Icons.person_outline,
            ),
            title: 'Edit Profile',
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ProfileUIColors.profileGray800,
            ),
            chevronColor: ProfileUIColors.profileGray400,
          ),
          Divider(height: 1, thickness: 1, color: ProfileUIColors.profileGray100),
          _accountRow(
            context: context,
            onTap: onEditPreferences,
            iconContainer: profileAccountIconContainer(
              backgroundColor: ProfileUIColors.profileGreen.withValues(alpha: 0.1),
              iconColor: ProfileUIColors.profileGreen,
              icon: Icons.tune,
            ),
            title: 'Edit Preferences',
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ProfileUIColors.profileGray800,
            ),
            chevronColor: ProfileUIColors.profileGray400,
          ),
          Divider(height: 1, thickness: 1, color: ProfileUIColors.profileGray100),
          _accountRow(
            context: context,
            onTap: () => _handleLogout(context),
            iconContainer: profileAccountIconContainer(
              backgroundColor: ProfileUIColors.profileRed.withValues(alpha: 0.1),
              iconColor: ProfileUIColors.profileRed,
              icon: Icons.logout_rounded,
            ),
            title: 'Logout',
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ProfileUIColors.profileRed,
            ),
            chevronColor: ProfileUIColors.profileRed.withValues(alpha: 0.7),
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
      decoration: ProfileCardDecoration.card(),
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
          decoration: ProfileCardDecoration.card(),
          child: Row(
            children: [
              profileIconContainer(
                gradient: ProfileIconGradient.gamification,
                icon: const Icon(Icons.emoji_events, color: Colors.white, size: 24),
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
                        color: ProfileUIColors.profileGray800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'XP, badges, and challenges',
                      style: TextStyle(fontSize: 12, color: ProfileUIColors.profileGray500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 22, color: ProfileUIColors.profileGray400),
            ],
          ),
        ),
      ),
    );
  }
}
