import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../gamification/presentation/cubit/gamification_cubit.dart';
import '../../../gamification/presentation/cubit/gamification_state.dart';
import '../../../gamification/presentation/screens/gamification_profile_screen.dart';
import '../bloc/load_status.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_section.dart';
import '../bloc/profile_state.dart';
import '../widgets/profile_character_card.dart';

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

      context.read<ProfileBloc>().add(const ProfileStarted());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ───
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

              // ─── Character Card (backend-driven) ───
              BlocBuilder<GamificationCubit, GamificationState>(
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
                    GamificationLoaded(:final profile) =>
                      ProfileCharacterCard(
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

              // ─── Gamification Entry ───
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
            ],
          ),
        ),
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
