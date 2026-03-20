import 'package:geolocator/geolocator.dart';

/// Thin wrapper around [Geolocator] for foreground GPS tracking.
///
/// Handles permission checks and exposes a position stream.
/// No BLoC dependency — pure service, injectable via constructor.
class LocationService {
  /// Checks the current permission status and requests permission if needed.
  ///
  /// Returns the resulting [LocationPermission].
  /// Caller decides what to do with [denied] vs [deniedForever].
  Future<LocationPermission> checkAndRequestPermission() async {
    // 1) Is the location service enabled at OS level?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Service disabled — caller should treat as denied.
      return LocationPermission.denied;
    }

    // 2) Check current permission status
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // First-time or previously denied (not permanently) — request
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  /// Continuous position stream with high accuracy.
  ///
  /// [distanceFilter] in meters — minimum displacement before the next update.
  Stream<Position> positionStream({int distanceFilter = 5}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Single-shot current position (fallback / initial seed).
  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Opens the device app settings page.
  ///
  /// Useful when permission is permanently denied.
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Opens the device location settings page.
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
