import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/gamification_profile_dto.dart';
import '../cubit/gamification_cubit.dart';
import '../cubit/gamification_state.dart';
import '../widgets/badge_tile.dart';
import '../widgets/challenges_placeholder.dart';
import '../widgets/xp_card.dart';

/// MOB-9: Gamification summary screen.
///
/// Thin orchestrator only — delegates rendering to widget files.
/// Calls [GamificationCubit.fetchProfile] once on first open.
class GamificationProfileScreen extends StatefulWidget {
  const GamificationProfileScreen({super.key});

  @override
  State<GamificationProfileScreen> createState() =>
      _GamificationProfileScreenState();
}

class _GamificationProfileScreenState extends State<GamificationProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Single fetch via postFrameCallback to avoid calling during build.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      context.read<GamificationCubit>().fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: BlocBuilder<GamificationCubit, GamificationState>(
          builder: (context, state) {
            return switch (state) {
              GamificationInitial() => _buildLoading(),
              GamificationLoading() => _buildLoading(),
              GamificationError(:final message) => _buildError(context, message),
              GamificationLoaded(:final profile, :final isMock) =>
                _GamificationLoadedBody(profile: profile, isMock: isMock),
            };
          },
        ),
      ),
    );
  }

  // ─── Loading ───
  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF0096FF)),
    );
  }

  // ─── Error ───
  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFFF6B6B)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Color(0xFF5F7A8F)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () =>
                  context.read<GamificationCubit>().fetchProfile(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0096FF),
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
  final bool isMock;

  const _GamificationLoadedBody({
    required this.profile,
    required this.isMock,
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
                // Back button + mock chip
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.chevron_left, size: 28),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const Spacer(),
                    if (isMock) _buildMockChip(),
                  ],
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
        if (profile.badges.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                profile.badgesSectionTitle.isNotEmpty
                    ? profile.badgesSectionTitle
                    : 'Achievement Badges',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50)),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid.count(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children:
                  profile.badges.map((b) => BadgeTile(badge: b)).toList(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],

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

  /// Subtle "Preview data" chip shown when data is mock fallback.
  Widget _buildMockChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD166).withValues(alpha: 0.5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.science_outlined, size: 14, color: Color(0xFFB8860B)),
          SizedBox(width: 4),
          Text(
            'Preview data',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFFB8860B)),
          ),
        ],
      ),
    );
  }
}
