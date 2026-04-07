import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/navigation/navigation_service.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/theme_cubit.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:mobile/features/booking/presentation/widgets/search/booking_search_field_styles.dart';

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
import '../widgets/profile_photo_viewer.dart';
import 'check_in_history_screen.dart';
import 'travel_statistics_screen.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeaderSection(
                onOpenEditProfile: () {
                  final s = context.read<ProfileBloc>().state;
                  final initial = s.profile ??
                      UserProfile.defaultForDraft(userId: '', email: '');
                  _openEditProfileSheet(context, initial);
                },
              ),

              const SizedBox(height: 16),

              _ProfileMenuCard(
                title: 'Edit Profile',
                subtitle: 'Name, photo, country, date of birth',
                icon: Icons.edit_rounded,
                iconGradient: ProfileIconGradient.editProfile(context),
                trailing: Icon(
                  Icons.edit_outlined,
                  size: 22,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: () {
                  final s = context.read<ProfileBloc>().state;
                  final initial = s.profile ??
                      UserProfile.defaultForDraft(
                        userId: s.profile?.userId ?? '',
                        email: s.profile?.email ?? '',
                      );
                  _openEditProfileSheet(context, initial);
                },
              ),
              const SizedBox(height: 16),

              _ProfileMenuCard(
                title: 'Travel Preferences',
                subtitle: 'Personalize recommendations',
                icon: Icons.tune_rounded,
                iconGradient: ProfileIconGradient.editProfile(context),
                onTap: () {
                  final profileBloc = context.read<ProfileBloc>();
                  final state = profileBloc.state;
                  final initial = state.preferences ??
                      UserPreferences.defaultForDraft(
                        userId: state.profile?.userId ?? '',
                      );
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => BlocProvider.value(
                      value: profileBloc,
                      child: EditPreferencesSheet(initialPrefs: initial),
                    ),
                  );
                },
                child: const _TravelPreferencesPreview(),
              ),
              const SizedBox(height: 16),

              _ProfileMenuCard(
                title: 'Check-in History',
                subtitle: "Places you've visited",
                icon: Icons.schedule_rounded,
                iconGradient: ProfileIconGradient.checkIn(context),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CheckInHistoryScreen()),
                  );
                },
                child: const _CheckInHistoryPreview(),
              ),
              const SizedBox(height: 16),

              _ProfileMenuCard(
                title: 'Travel Statistics',
                subtitle: 'Your journey so far',
                icon: Icons.bar_chart_rounded,
                iconGradient: ProfileIconGradient.stats,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TravelStatisticsScreen()),
                  );
                },
                child: const _TravelStatisticsPreview(),
              ),
              const SizedBox(height: 16),

              _ProfileMenuCard(
                title: 'Achievements',
                subtitle: 'XP, badges, and challenges',
                icon: Icons.emoji_events_rounded,
                iconGradient: ProfileIconGradient.achievements(context),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GamificationProfileScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              const _ActionsCard(),
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
  final VoidCallback onOpenEditProfile;

  const _ProfileHeaderSection({required this.onOpenEditProfile});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        BlocBuilder<ProfileBloc, ProfileState>(
          buildWhen: (prev, curr) =>
              prev.profile != curr.profile ||
              prev.profilePhotoBytes != curr.profilePhotoBytes,
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
                void openPhotoViewer() {
                  showProfilePhotoViewer(
                    context,
                    profilePhotoBytes: profileState.profilePhotoBytes,
                    profileImageUrl: profileState.profile?.profileImageUrl,
                  );
                }

                return switch (state) {
                  GamificationInitial() || GamificationLoading() =>
                    ProfileCharacterCard(
                      name: displayName,
                      roleText: '—',
                      levelText: '—',
                      profileImageUrl: profileState.profile?.profileImageUrl,
                      profilePhotoBytes: profileState.profilePhotoBytes,
                      onInfoTap: onOpenEditProfile,
                      onAvatarTap: openPhotoViewer,
                    ),
                  GamificationError() => ProfileCharacterCard(
                      name: displayName,
                      roleText: 'Traveler',
                      levelText: '—',
                      profileImageUrl: profileState.profile?.profileImageUrl,
                      profilePhotoBytes: profileState.profilePhotoBytes,
                      onInfoTap: onOpenEditProfile,
                      onAvatarTap: openPhotoViewer,
                    ),
                  GamificationLoaded(:final profile) => ProfileCharacterCard(
                      name: displayName,
                      roleText: profile.roleText,
                      levelText: profile.levelText,
                      totalXp: profile.totalXp,
                      xpProgressPercent: profile.xpProgressPercent,
                      profileImageUrl: profileState.profile?.profileImageUrl,
                      profilePhotoBytes: profileState.profilePhotoBytes,
                      onInfoTap: onOpenEditProfile,
                      onAvatarTap: openPhotoViewer,
                    ),
                };
              },
            );
          },
        ),
      ],
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final LinearGradient iconGradient;
  final VoidCallback onTap;
  final Widget? child;
  /// When null, shows a chevron (push navigation). Pass a custom widget for sheets / other affordances.
  final Widget? trailing;

  const _ProfileMenuCard({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconGradient,
    required this.onTap,
    this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = iconGradient.colors.first;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: double.infinity,
          child: profileGlassMenuCard(
            context: context,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      profileIconContainer(
                        context: context,
                        accentColor: accent,
                        icon: icon,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      trailing ??
                          Icon(Icons.chevron_right, size: 22, color: cs.onSurfaceVariant),
                    ],
                  ),
                  if (child != null) ...[
                    const SizedBox(height: 12),
                    child!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Theme toggle + logout (moved from app bar for clearer hierarchy).
class _ActionsCard extends StatelessWidget {
  const _ActionsCard();

  Future<void> _logout(BuildContext context) async {
    try {
      await context.read<AuthRepository>().logout();
    } finally {
      NavigationService.resetToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = context.vacanzaTokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Moon: cool blue-slate (not primary cyan). Sun: warm amber when on dark UI.
    final themeToggleIconColor = isDark
        ? tokens.vividAmber
        : Color.lerp(
            const Color(0xFF546E7A),
            const Color(0xFF5C6BC0),
            0.35,
          )!;
    return profileGlassMenuCard(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.palette_outlined, color: cs.onSurfaceVariant),
              title: Text(
                isDark ? 'Light mode' : 'Dark mode',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              subtitle: Text(
                'App appearance',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              trailing: IconButton(
                tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: themeToggleIconColor,
                  size: 26,
                ),
                onPressed: () => context.read<ThemeCubit>().toggle(),
              ),
              onTap: () => context.read<ThemeCubit>().toggle(),
            ),
            Divider(
              height: 1,
              color: BookingSearchFieldStyles.fieldBorderInactive(context),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.logout_rounded, color: cs.error),
              title: Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.error,
                ),
              ),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _TravelPreferencesPreview extends StatelessWidget {
  const _TravelPreferencesPreview();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (p, n) =>
          p.preferencesStatus != n.preferencesStatus ||
          p.preferences != n.preferences,
      builder: (context, state) {
        if (state.preferencesStatus == LoadStatus.loading &&
            state.preferences == null) {
          return Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Text('Loading…', style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          );
        }

        if (state.preferencesStatus == LoadStatus.failure) {
          final msg =
              state.errorFor(ProfileSection.preferences) ?? 'Error';
          return Text(
            msg,
            style: TextStyle(color: cs.error, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          );
        }

        final prefs = state.preferences;
        if (prefs == null) {
          return Text(
            'No preferences set',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          );
        }

        final travelStyle = prefs.travelStyle != null
            ? _capitalize(prefs.travelStyle!.replaceAll('_', ' '))
            : '—';
        final cats = prefs.favoriteCategories.take(3).toList();
        final extra = prefs.favoriteCategories.length - cats.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Travel style: $travelStyle',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            if (cats.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...cats.map(
                    (c) => ProfileChipStyle.categoryPill(
                      context,
                      _capitalize(c),
                    ),
                  ),
                  if (extra > 0)
                    ProfileChipStyle.extraPill(context, '+$extra'),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _TravelStatisticsPreview extends StatelessWidget {
  const _TravelStatisticsPreview();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (prev, curr) =>
          prev.statsStatus != curr.statsStatus || prev.stats != curr.stats,
      builder: (context, state) {
        if (state.statsStatus == LoadStatus.loading && state.stats == null) {
          return Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Text('Loading…', style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          );
        }
        if (state.statsStatus == LoadStatus.failure) {
          return Text(
            state.errorFor(ProfileSection.stats) ?? 'Error',
            style: TextStyle(color: cs.error, fontSize: 12),
          );
        }
        final stats = state.stats;
        if (stats == null) return const SizedBox.shrink();
        if (stats.visitedPoisCount == 0) {
          return Text(
            'No check-ins yet. Start exploring!',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          );
        }

        return LayoutBuilder(
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
                        context: context,
                        title: Text('${stats.visitedPoisCount}'),
                        subtitle: 'Total places visited',
                      ),
                    ),
                    const SizedBox(width: gap),
                    SizedBox(
                      width: tileWidth,
                      child: profileStatTile(
                        context: context,
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
                        context: context,
                        title: Text(_capitalize(stats.favoriteCategory ?? '—')),
                        subtitle: 'Favorite category',
                      ),
                    ),
                    const SizedBox(width: gap),
                    SizedBox(
                      width: tileWidth,
                      child: profileStatTile(
                        context: context,
                        title: Text('${stats.distinctCategoriesCount}'),
                        subtitle: 'Categories explored',
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CheckInHistoryPreview extends StatelessWidget {
  const _CheckInHistoryPreview();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (prev, curr) =>
          prev.checkInsStatus != curr.checkInsStatus ||
          prev.checkIns != curr.checkIns,
      builder: (context, state) {
        if (state.checkInsStatus == LoadStatus.loading &&
            state.checkIns.isEmpty) {
          return Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Text('Loading…', style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          );
        }
        if (state.checkInsStatus == LoadStatus.failure) {
          return Text(
            state.errorFor(ProfileSection.checkIns) ?? 'Error',
            style: TextStyle(color: cs.error, fontSize: 12),
          );
        }
        if (state.checkIns.isEmpty) {
          return Text(
            'No check-ins yet. Start exploring!',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          );
        }

        final preview = state.checkIns.take(3).toList();
        return Column(
          children: preview.map((c) => _CheckInRow(checkIn: c)).toList(),
        );
      },
    );
  }
}

class _CheckInRow extends StatelessWidget {
  final CheckIn checkIn;
  const _CheckInRow({required this.checkIn});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.20)),
            ),
            child: Icon(Icons.place_outlined, size: 18, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkIn.poiName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_capitalize(checkIn.category)} • ${_formatDate(checkIn.checkedInAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
