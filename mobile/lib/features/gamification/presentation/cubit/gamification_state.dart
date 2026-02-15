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
///
/// [isMock] is `true` when data comes from the local mock fallback
/// (backend returned 404). UI can show a subtle "Preview data" indicator.
class GamificationLoaded extends GamificationState {
  final GamificationProfileDto profile;
  final bool isMock;
  const GamificationLoaded(this.profile, {this.isMock = false});
}

/// Fetch failed.
class GamificationError extends GamificationState {
  final String message;
  const GamificationError(this.message);
}
