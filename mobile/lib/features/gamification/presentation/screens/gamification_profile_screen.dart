import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';

import '../../data/models/gamification_profile_dto.dart';
import '../cubit/gamification_cubit.dart';
import '../cubit/gamification_state.dart';
import '../widgets/badge_grid_section.dart';
import '../widgets/challenges_placeholder.dart';
import '../widgets/xp_card.dart';

/// MOB-9: Gamification summary screen.
///
/// Thin orchestrator only — delegates rendering to widget files.
/// Does NOT auto-fetch; relies on [GamificationCubit] already having
/// data from [ProfileScreen]. User can retry on error.
class GamificationProfileScreen extends StatelessWidget {
  const GamificationProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    log('[GAM_UI] GamificationProfileScreen opened');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: BlocBuilder<GamificationCubit, GamificationState>(
          builder: (context, state) {
            return switch (state) {
              GamificationInitial() => _buildLoading(),
              GamificationLoading() => _buildLoading(),
              GamificationError(:final message) =>
                _buildError(context, message),
              GamificationLoaded(:final profile) =>
                _GamificationLoadedBody(profile: profile),
            };
          },
        ),
      ),
    );
  }

  // ─── Loading ───
  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // ─── Error ───
  Widget _buildError(BuildContext context, String message) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                log('[GAM_UI] GamificationProfileScreen retry tapped');
                context.read<GamificationCubit>().fetchProfile();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: context.mapControlAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────── Loaded Body ────────────────────────

class _GamificationLoadedBody extends StatelessWidget {
  final GamificationProfileDto profile;

  const _GamificationLoadedBody({
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ─── Header ───
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left, size: 28),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  profile.roleText,
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF5F7A8F)),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.levelText,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // ─── XP Progress Ring ───
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: XpCard(profile: profile),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // ─── Badge Grid ───
        SliverToBoxAdapter(
          child: BadgeGridSection(
            sectionTitle: profile.badgesSectionTitle,
            badges: profile.badges,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // ─── Challenges Placeholder ───
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: ChallengesPlaceholder(),
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}
