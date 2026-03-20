/// Events for [CheckinBloc].
abstract class CheckinEvent {
  const CheckinEvent();
}

/// Trigger an auto check-in with the user's current GPS position
/// and candidate POI IDs from the map viewport.
///
/// Dispatched by the LocationBloc listener in HomeMapScreen.
class TriggerAutoCheckin extends CheckinEvent {
  final double latitude;
  final double longitude;
  final List<String> candidatePoiIds;

  const TriggerAutoCheckin({
    required this.latitude,
    required this.longitude,
    required this.candidatePoiIds,
  });
}
