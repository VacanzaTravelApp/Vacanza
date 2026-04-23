import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

/// Pure character card widget for the Profile hub.
///
/// Receives all data via constructor — no Bloc access inside.
/// Used by [ProfileScreen] with values from [GamificationCubit] state.
class ProfileCharacterCard extends StatelessWidget {
  final String name;
  final String roleText;
  final String levelText;
  final int? totalXp;
  final int? xpProgressPercent;
  final String? profileImageUrl;

  /// Binary avatar when [UserProfile.hasProfilePhoto].
  final Uint8List? profilePhotoBytes;

  /// Opens profile settings (e.g. Edit Profile sheet). Typically the name / XP column.
  final VoidCallback? onInfoTap;

  /// Opens full-screen photo preview; keep separate from [onInfoTap].
  final VoidCallback? onAvatarTap;

  const ProfileCharacterCard({
    super.key,
    required this.name,
    required this.roleText,
    required this.levelText,
    this.totalXp,
    this.xpProgressPercent,
    this.profileImageUrl,
    this.profilePhotoBytes,
    this.onInfoTap,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final clampedPercent = (xpProgressPercent ?? 0).clamp(0, 100);
    final showXp = totalXp != null && xpProgressPercent != null;
    final cs = Theme.of(context).colorScheme;
    final gradientColors = context.mapControlActiveGradientColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final inner = Container(
      decoration: BoxDecoration(
        color: isDark
            ? cs.surface.withValues(alpha: 0.92)
            : context.lightGlassPanelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.secondary.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.08),
            blurRadius: 26,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    gradientColors.first.withValues(alpha: 0.10),
                    gradientColors.last.withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with gradient border
                _buildAvatar(context),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: onInfoTap == null
                      ? _buildInfoColumn(
                          context: context,
                          showXp: showXp,
                          clampedPercent: clampedPercent,
                        )
                      : Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: onInfoTap,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                top: 4,
                                right: 4,
                                bottom: 8,
                              ),
                              child: _buildInfoColumn(
                                context: context,
                                showXp: showXp,
                                clampedPercent: clampedPercent,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isDark) return inner;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: inner,
      ),
    );
  }

  Widget _buildInfoColumn({
    required BuildContext context,
    required bool showXp,
    required int clampedPercent,
  }) {
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.30)),
          ),
          child: Text(
            roleText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          levelText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: accent,
          ),
        ),
        if (showXp) ...[
          const SizedBox(height: 4),
          Text(
            '$totalXp XP • $clampedPercent% to next level',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clampedPercent / 100,
              minHeight: 4,
              backgroundColor: cs.outline.withValues(alpha: 0.25),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        ],
      ],
    );
  }

  static const double _avatarOuter = 72;
  static const double _ring = 3;
  static double get _avatarInner => _avatarOuter - 2 * _ring;

  Widget _buildAvatar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gradientColors = context.mapControlActiveGradientColors;
    final hasBytes =
        profilePhotoBytes != null && profilePhotoBytes!.isNotEmpty;
    final hasUrl = profileImageUrl != null && profileImageUrl!.trim().isNotEmpty;

    Widget inner;
    if (hasBytes) {
      inner = Image.memory(
        profilePhotoBytes!,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.person, size: 36, color: Color(0xFF9CA3AF)),
        ),
      );
    } else if (hasUrl) {
      inner = Image.network(
        profileImageUrl!.trim(),
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.medium,
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: Icon(Icons.person, size: 36, color: Color(0xFF9CA3AF)),
          );
        },
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.person, size: 36, color: Color(0xFF9CA3AF)),
        ),
      );
    } else {
      inner = const Center(
        child: Icon(Icons.person, size: 36, color: Color(0xFF9CA3AF)),
      );
    }

    final avatar = Container(
      width: _avatarOuter,
      height: _avatarOuter,
      padding: const EdgeInsets.all(_ring),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradientColors,
        ),
      ),
      child: ClipOval(
        child: SizedBox(
          width: _avatarInner,
          height: _avatarInner,
          child: ColoredBox(
            color: cs.surfaceContainerHighest,
            child: inner,
          ),
        ),
      ),
    );

    if (onAvatarTap == null) return avatar;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onAvatarTap,
        child: avatar,
      ),
    );
  }

}
