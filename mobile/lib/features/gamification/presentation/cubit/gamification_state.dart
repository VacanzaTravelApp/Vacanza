import '../../data/models/gamification_profile_dto.dart';

/// Sealed state hierarchy for [GamificationCubit].
sealed class GamificationState {
  const GamificationState();
}

/// No fetch attempted yet.
class GamificationInitial extends GamificationState {
  const GamificationInitial();
}

/// Fetch in progress.
class GamificationLoading extends GamificationState {
  const GamificationLoading();
}

/// Profile loaded successfully.
class GamificationLoaded extends GamificationState {
  final GamificationProfileDto profile;
  const GamificationLoaded(this.profile);
}

/// Fetch failed.
class GamificationError extends GamificationState {
  final String message;
  const GamificationError(this.message);
}
