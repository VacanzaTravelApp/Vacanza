import 'dart:math' as math;

import 'package:mobile/features/chat/data/models/chat_models.dart';

/// Normalized route model for map rendering (day-based waypoints).
///
/// Keeps this independent of chat transport models so we can also hydrate it
/// from saved `/routes/{routeId}` responses later.
class RouteMapModel {
  final String? title;
  final String? destination;
  final int totalDays;
  final List<RouteMapDay> days;
  final String? notes;

  final bool? tripDatesUserSpecified;
  final String? tripStartDate;
  final List<DailyWeatherSummary> weatherForecast;
  final List<DayPartWeatherDay> weatherDayParts;

  const RouteMapModel({
    required this.title,
    required this.destination,
    required this.totalDays,
    required this.days,
    this.notes,
    this.tripDatesUserSpecified,
    this.tripStartDate,
    this.weatherForecast = const [],
    this.weatherDayParts = const [],
  });

  factory RouteMapModel.fromChat(ChatRouteData route) {
    final days =
        route.days
            .where((d) => d.day > 0)
            .map(
              (d) => RouteMapDay(
                day: d.day,
                title: d.title,
                waypoints:
                    d.waypoints
                        .where((w) => w.latitude != null && w.longitude != null)
                        .map(
                          (w) => RouteMapWaypoint(
                            name: w.name,
                            category: w.category,
                            description: w.description,
                            day: w.day,
                            order: w.order,
                            latitude: w.latitude!,
                            longitude: w.longitude!,
                            arrivalTimeLocal: w.arrivalTimeLocal,
                            departureTimeLocal: w.departureTimeLocal,
                            timeSlot: w.timeSlot,
                            estimatedDurationMin: w.estimatedDurationMin,
                            travelFromPreviousMin: w.travelFromPreviousMin,
                            unavailable: w.unavailable,
                          ),
                        )
                        .toList()
                      ..sort((a, b) => a.order.compareTo(b.order)),
              ),
            )
            .toList()
          ..sort((a, b) => a.day.compareTo(b.day));

    final computedTotalDays =
        route.totalDays > 0
            ? route.totalDays
            : (days.isNotEmpty ? days.length : 0);

    return RouteMapModel(
      title: route.title,
      destination: route.destination,
      totalDays: computedTotalDays,
      days: days,
      notes: route.notes,
      tripDatesUserSpecified: route.tripDatesUserSpecified,
      tripStartDate: route.tripStartDate,
      weatherForecast: route.weatherForecast,
      weatherDayParts: route.weatherDayParts,
    );
  }
}

class RouteMapDay {
  final int day;
  final String? title;
  final List<RouteMapWaypoint> waypoints;

  const RouteMapDay({
    required this.day,
    required this.title,
    required this.waypoints,
  });
}

class RouteMapWaypoint {
  final String name;
  final String? category;
  final String? description;
  final int day;
  final int order;
  final double latitude;
  final double longitude;
  final String? arrivalTimeLocal;
  final String? departureTimeLocal;
  final String? timeSlot;
  final int? estimatedDurationMin;
  final int? travelFromPreviousMin;
  final bool unavailable;

  const RouteMapWaypoint({
    required this.name,
    required this.category,
    required this.description,
    required this.day,
    required this.order,
    required this.latitude,
    required this.longitude,
    required this.arrivalTimeLocal,
    required this.departureTimeLocal,
    required this.timeSlot,
    required this.estimatedDurationMin,
    required this.travelFromPreviousMin,
    required this.unavailable,
  });
}

/// Calendar day **1** if that day exists in the model; otherwise the earliest day.
int firstCalendarDayForMap(RouteMapModel model) {
  if (model.days.isEmpty) return 1;
  final sorted = [...model.days]..sort((a, b) => a.day.compareTo(b.day));
  for (final d in sorted) {
    if (d.day == 1) return 1;
  }
  return sorted.first.day;
}

/// Waypoints for a single calendar day, ordered by [RouteMapWaypoint.order].
List<RouteMapWaypoint> waypointsForDay(RouteMapModel model, int day) {
  for (final d in model.days) {
    if (d.day == day) {
      final wps = [...d.waypoints]..sort((a, b) => a.order.compareTo(b.order));
      return wps;
    }
  }
  return const [];
}

/// First map fit after chat / open map: same day policy as [firstCalendarDayForMap].
List<RouteMapWaypoint> waypointsForInitialMapDay(RouteMapModel model) {
  return waypointsForDay(model, firstCalendarDayForMap(model));
}

/// Day tabs: use model days when present; otherwise `1..totalDays` (backend shape quirks).
List<int> dayChipNumbers(RouteMapModel model) {
  final fromModel = model.days.map((d) => d.day).toList()..sort();
  if (fromModel.isNotEmpty) return fromModel;
  final n = model.totalDays;
  if (n <= 0) return const [1];
  return List.generate(n, (i) => i + 1);
}

/// Picks [preferred] if that day exists on the route; otherwise [firstCalendarDayForMap].
/// Respects [RouteMapModel.totalDays] so [ActiveRouteCubit.setActiveDay] can apply.
int effectiveActiveDayForRoute(RouteMapModel route, int preferred) {
  final td = route.totalDays;
  bool inRange(int d) => td <= 0 || (d >= 1 && d <= td);

  final nums = route.days.map((d) => d.day).toSet();
  if (nums.isEmpty) {
    if (td <= 0) return 1;
    return preferred.clamp(1, td);
  }
  if (nums.contains(preferred) && inRange(preferred)) return preferred;
  final fb = firstCalendarDayForMap(route);
  if (nums.contains(fb) && inRange(fb)) return fb;
  final sorted = nums.toList()..sort();
  for (final n in sorted) {
    if (inRange(n)) return n;
  }
  if (td > 0) return preferred.clamp(1, td);
  return sorted.first;
}

/// All waypoints across days, sorted by day then order (for map fitting).
List<RouteMapWaypoint> allWaypointsForMap(RouteMapModel model) {
  final sortedDays = [...model.days]..sort((a, b) => a.day.compareTo(b.day));
  final out = <RouteMapWaypoint>[];
  for (final d in sortedDays) {
    final wps = [...d.waypoints]..sort((a, b) => a.order.compareTo(b.order));
    out.addAll(wps);
  }
  return out;
}

/// Geographic bounds covering [waypoints], or null if empty.
({double minLat, double maxLat, double minLng, double maxLng})?
boundsOfWaypoints(List<RouteMapWaypoint> waypoints) {
  if (waypoints.isEmpty) return null;
  var minLat = waypoints.first.latitude;
  var maxLat = waypoints.first.latitude;
  var minLng = waypoints.first.longitude;
  var maxLng = waypoints.first.longitude;
  for (final w in waypoints.skip(1)) {
    minLat = math.min(minLat, w.latitude);
    maxLat = math.max(maxLat, w.latitude);
    minLng = math.min(minLng, w.longitude);
    maxLng = math.max(maxLng, w.longitude);
  }
  const eps = 0.002;
  if ((maxLat - minLat).abs() < eps) {
    minLat -= eps;
    maxLat += eps;
  }
  if ((maxLng - minLng).abs() < eps) {
    minLng -= eps;
    maxLng += eps;
  }
  return (minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng);
}

/// Initial bearing from first to last waypoint (degrees, 0–360), or null.
double? bearingFirstToLast(List<RouteMapWaypoint> waypoints) {
  if (waypoints.length < 2) return null;
  final a = waypoints.first;
  final b = waypoints.last;
  return initialBearingDegrees(
    a.latitude,
    a.longitude,
    b.latitude,
    b.longitude,
  );
}

double initialBearingDegrees(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  final phi1 = lat1 * math.pi / 180;
  final phi2 = lat2 * math.pi / 180;
  final dL = (lng2 - lng1) * math.pi / 180;
  final y = math.sin(dL) * math.cos(phi2);
  final x =
      math.cos(phi1) * math.sin(phi2) -
      math.sin(phi1) * math.cos(phi2) * math.cos(dL);
  final brng = math.atan2(y, x) * 180 / math.pi;
  return (brng + 360) % 360;
}
