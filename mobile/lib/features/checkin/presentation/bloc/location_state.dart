/// Possible statuses for [LocationBloc].
enum LocationStatus {
  /// Initial state — tracking has not started yet.
  initial,

  /// GPS stream is active and delivering coordinates.
  tracking,

  /// User denied location permission (or location service is disabled).
  permissionDenied,

  /// User permanently denied location permission — must open app settings.
  permissionDeniedForever,

  /// An unexpected error occurred (e.g. stream error).
  error,
}

/// Immutable state for [LocationBloc].
class LocationState {
  final LocationStatus status;
  final double? latitude;
  final double? longitude;
  final String? errorMessage;

  const LocationState({
    required this.status,
    this.latitude,
    this.longitude,
    this.errorMessage,
  });

  factory LocationState.initial() => const LocationState(
        status: LocationStatus.initial,
      );

  LocationState copyWith({
    LocationStatus? status,
    double? latitude,
    double? longitude,
    String? errorMessage,
  }) {
    return LocationState(
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'LocationState(status: $status, lat: $latitude, lng: $longitude)';
}
