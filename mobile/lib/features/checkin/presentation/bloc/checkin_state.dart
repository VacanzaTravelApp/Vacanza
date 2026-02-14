import '../../data/models/auto_checkin_response_dto.dart';

/// Possible statuses for [CheckinBloc].
enum CheckinStatus {
  /// No check-in attempted yet.
  initial,

  /// API call in progress.
  loading,

  /// Check-in succeeded (response available).
  success,

  /// Check-in failed (error message available).
  failure,
}

/// Immutable state for [CheckinBloc].
class CheckinState {
  final CheckinStatus status;
  final AutoCheckinResponseDto? response;
  final String? errorMessage;

  const CheckinState({
    required this.status,
    this.response,
    this.errorMessage,
  });

  factory CheckinState.initial() => const CheckinState(
        status: CheckinStatus.initial,
      );

  CheckinState copyWith({
    CheckinStatus? status,
    AutoCheckinResponseDto? response,
    String? errorMessage,
  }) {
    return CheckinState(
      status: status ?? this.status,
      response: response ?? this.response,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'CheckinState(status: $status, response: $response, error: $errorMessage)';
}
