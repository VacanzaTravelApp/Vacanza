import '../../data/models/badge_dto.dart';
import '../../data/models/gamification_profile_dto.dart';

sealed class GamificationState {
  const GamificationState();
}

class GamificationInitial extends GamificationState {
  const GamificationInitial();
}

class GamificationLoading extends GamificationState {
  const GamificationLoading();
}

class GamificationLoaded extends GamificationState {
  final GamificationProfileDto profile;

  /// Badges that were just earned in this fetch cycle.
  /// Empty on the initial load — only populated after a [refresh] call.
  final List<BadgeDto> newlyEarnedBadges;

  const GamificationLoaded(this.profile, {this.newlyEarnedBadges = const []});
}

class GamificationError extends GamificationState {
  final String message;
  const GamificationError(this.message);
}
