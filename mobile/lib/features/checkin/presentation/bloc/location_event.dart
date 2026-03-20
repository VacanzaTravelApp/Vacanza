/// Events for [LocationBloc].
abstract class LocationEvent {
  const LocationEvent();
}

/// Start foreground GPS tracking.
///
/// Dispatched from [HomeMapScreen.initState].
class StartTracking extends LocationEvent {
  const StartTracking();
}

/// Stop GPS tracking and cancel the position stream.
///
/// Dispatched from [HomeMapScreen.dispose].
class StopTracking extends LocationEvent {
  const StopTracking();
}

/// Internal event — emitted by LocationBloc itself when a new
/// position arrives from the Geolocator stream.
///
/// Public (not file-private) so it lives in a separate file.
/// Consumers should never dispatch this manually.
class LocationUpdated extends LocationEvent {
  final double latitude;
  final double longitude;

  const LocationUpdated(this.latitude, this.longitude);
}
