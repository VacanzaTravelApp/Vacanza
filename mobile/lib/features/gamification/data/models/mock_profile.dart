import 'badge_dto.dart';
import 'gamification_profile_dto.dart';
import 'stat_dto.dart';

/// Returns a realistic mock [GamificationProfileDto] for demo purposes.
///
/// Badge keys and level titles match the backend seed data.
/// Remove this once GET /users/me/gamification is live.
GamificationProfileDto mockGamificationProfile() {
  return GamificationProfileDto(
    roleText: 'Urban Adventurer',
    levelText: 'Level 5',
    xpProgressPercent: 65,
    xpToNextLevel: 500,
    totalXp: 1325,
    badgesSectionTitle: 'Achievement Badges',
    stats: const [
      StatDto(label: 'Places', value: 8),
      StatDto(label: 'Badges', value: 3),
      StatDto(label: 'Days', value: 12),
    ],
    badges: const [
      BadgeDto(id: 1, title: 'First Step', key: 'speed', earned: true),
      BadgeDto(id: 2, title: 'Foodie', key: 'foodie', earned: true),
      BadgeDto(id: 3, title: 'Explorer', key: 'explorer', earned: true),
      BadgeDto(id: 4, title: 'Culture Buff', key: 'culture', earned: false),
      BadgeDto(id: 5, title: 'Nature Lover', key: 'nature', earned: false),
    ],
  );
}
