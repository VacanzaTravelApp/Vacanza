import '../../data/models/auto_checkin_response_dto.dart';

/// Possible statuses for [CheckinBloc].
///
/// MOB-4: Replaced generic success/failure with 4 distinct outcomes
/// so consumers (UI, MOB-12 gamification) can differentiate between
/// a new check-in, a duplicate, and a no-match.
enum CheckinStatus {
  /// No check-in attempted yet.
  initial,

  /// API call in progress.
  loading,

  /// Server created a NEW check-in (checkInId != null).
  /// Local state should be updated. gamificationTriggered preserved for MOB-12.
  newCreated,

  /// Server says "already checked in" (success==true, checkInId==null).
  /// No local state mutation needed — idempotent.
  duplicate,

  /// Server says "no matching POI within range" (success==false).
  /// No local state mutation needed.
  noMatch,

  /// Exception during API call (network, 401, 429, parse error).
  failure,
}

/// Immutable state for [CheckinBloc].
class CheckinState {
  final CheckinStatus status;
  final AutoCheckinResponseDto? response;
  final String? errorMessage;

  /// Preserved from the last [newCreated] response for MOB-12 gamification.
  final bool gamificationTriggered;

  const CheckinState({
    required this.status,
    this.response,
    this.errorMessage,
    this.gamificationTriggered = false,
  });

  factory CheckinState.initial() => const CheckinState(
        status: CheckinStatus.initial,
      );

  CheckinState copyWith({
    CheckinStatus? status,
    AutoCheckinResponseDto? response,
    String? errorMessage,
    bool? gamificationTriggered,
  }) {
    return CheckinState(
      status: status ?? this.status,
      response: response ?? this.response,
      errorMessage: errorMessage ?? this.errorMessage,
      gamificationTriggered:
          gamificationTriggered ?? this.gamificationTriggered,
    );
  }

  @override
  String toString() =>
      'CheckinState(status: $status, gamification: $gamificationTriggered, '
      'response: $response, error: $errorMessage)';
}
