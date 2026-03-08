import 'badge_dto.dart';
import 'stat_dto.dart';

/// Top-level response from `GET /users/me/gamification`.
///
/// All fields have safe defaults. [xpProgressPercent] is clamped to 0–100.
class GamificationProfileDto {
  final String roleText;
  final String levelText;
  final int xpProgressPercent;
  final int xpToNextLevel;
  final int totalXp;
  final String badgesSectionTitle;
  final List<StatDto> stats;
  final List<BadgeDto> badges;

  const GamificationProfileDto({
    required this.roleText,
    required this.levelText,
    required this.xpProgressPercent,
    required this.xpToNextLevel,
    required this.totalXp,
    required this.badgesSectionTitle,
    required this.stats,
    required this.badges,
  });

  factory GamificationProfileDto.fromJson(Map<String, dynamic> json) {
    final rawStats = json['stats'];
    final rawBadges = json['badges'];

    return GamificationProfileDto(
      roleText: (json['roleText'] ?? '').toString(),
      levelText: (json['levelText'] ?? '').toString(),
      xpProgressPercent:
          ((json['xpProgressPercent'] as num?)?.toInt() ?? 0).clamp(0, 100),
      xpToNextLevel: (json['xpToNextLevel'] as num?)?.toInt() ?? 0,
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      badgesSectionTitle: (json['badgesSectionTitle'] ?? '').toString(),
      stats: rawStats is List
          ? rawStats
              .map((e) => StatDto.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      badges: rawBadges is List
          ? rawBadges
              .map((e) => BadgeDto.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  @override
  String toString() =>
      'GamificationProfileDto(role: $roleText, level: $levelText, '
      'xp: $totalXp, progress: $xpProgressPercent%, '
      'stats: ${stats.length}, badges: ${badges.length})';
}
