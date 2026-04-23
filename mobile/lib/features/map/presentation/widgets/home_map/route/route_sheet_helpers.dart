import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/features/ai/utils/route_map.dart';
import 'package:mobile/features/map/presentation/bloc/map_bloc.dart';
import 'package:mobile/features/map/presentation/bloc/map_event.dart';

String routeWaypointTimeLine(RouteMapWaypoint w) {
  final arr = w.arrivalTimeLocal?.trim();
  final dep = w.departureTimeLocal?.trim();
  if (arr != null && arr.isNotEmpty && dep != null && dep.isNotEmpty) {
    return '$arr – $dep';
  }
  if (arr != null && arr.isNotEmpty) return arr;
  final ts = w.timeSlot?.trim();
  if (ts != null && ts.isNotEmpty) return ts;
  return '';
}

void fitMapToDayBounds(BuildContext context, RouteMapModel route, int day) {
  final wps = waypointsForDay(route, day);
  final b = boundsOfWaypoints(wps);
  final brg = bearingFirstToLast(wps);
  if (b == null) {
    return;
  }
  context.read<MapBloc>().add(
    FitRouteBoundsRequested(
      minLat: b.minLat,
      maxLat: b.maxLat,
      minLng: b.minLng,
      maxLng: b.maxLng,
      bearing: brg,
    ),
  );
}
