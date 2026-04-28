import 'dart:async';

class RouteOpenRequest {
  final String routeId;
  final int? day;

  const RouteOpenRequest({
    required this.routeId,
    this.day,
  });
}

/// Global one-way bus: request opening a saved route on the map.
///
/// This is used when a UI element (e.g. Trip Agenda) is shown from different
/// navigation stacks but still needs to trigger the map screen to load and open
/// a route sheet.
class RouteOpenRequests {
  RouteOpenRequests._();

  static final StreamController<RouteOpenRequest> _ctrl =
      StreamController<RouteOpenRequest>.broadcast();

  static Stream<RouteOpenRequest> get stream => _ctrl.stream;

  static void requestOpen(String routeId, {int? day}) {
    final rid = routeId.trim();
    if (rid.isEmpty) return;
    _ctrl.add(RouteOpenRequest(routeId: rid, day: day));
  }
}

