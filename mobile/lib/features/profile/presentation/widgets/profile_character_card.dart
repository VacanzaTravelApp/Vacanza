import 'package:flutter/material.dart';

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

  const ProfileCharacterCard({
    super.key,
    required this.name,
    required this.roleText,
    required this.levelText,
    this.totalXp,
    this.xpProgressPercent,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final clampedPercent = (xpProgressPercent ?? 0).clamp(0, 100);
    final showXp = totalXp != null && xpProgressPercent != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 32,
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
                    const Color(0xFF0096FF).withValues(alpha: 0.08),
                    const Color(0xFF2ECC71).withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar with gradient border
                _buildAvatar(),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Role chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          roleText,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF5F7A8F)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Level + XP
                      Text(
                        levelText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0096FF),
                        ),
                      ),
                      if (showXp) ...[
                        const SizedBox(height: 4),
                        Text(
                          '$totalXp XP • $clampedPercent% to next level',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 6),
                        // XP progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: clampedPercent / 100,
                            minHeight: 4,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor:
                                const AlwaysStoppedAnimation(Color(0xFF0096FF)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final hasUrl = profileImageUrl != null && profileImageUrl!.trim().isNotEmpty;
    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF0096FF), Color(0xFF2ECC71)],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          color: Colors.grey.shade200,
        ),
        clipBehavior: Clip.antiAlias,
        child: hasUrl
            ? Image.network(
                profileImageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (_, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: Icon(Icons.person, size: 36, color: Color(0xFF9CA3AF)),
                  );
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.person, size: 36, color: Color(0xFF9CA3AF)),
                ),
              )
            : const Center(
                child: Icon(Icons.person, size: 36, color: Color(0xFF9CA3AF)),
              ),
      ),
    );
  }

}
