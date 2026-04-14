import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:mobile/features/ai/utils/route_map.dart';

import 'route_stop_bitmap_builder.dart';

/// Route stop markers (bitmaps via [PointAnnotationOptions.image]).
///
/// Note: Style image registration can fail when Mapbox token/style load fails
/// (401 / invalid token). We keep this controller resilient by relying on
/// per-annotation bitmap images.
class RouteMarkersController {
  RouteMarkersController(this._map);

  final mb.MapboxMap _map;

  mb.PointAnnotationManager? _mgr;
  final Map<String, mb.PointAnnotation> _byKey = {};
  final Map<String, Uint8List> _routeIconCache = {};
  Completer<void>? _opLock;
  int _epoch = 0;

  bool get isReady => _mgr != null;

  Future<void> init() async {
    if (_mgr != null) {
      await dispose();
    }
    _mgr = await _map.annotations.createPointAnnotationManager();
    log('[RouteMarkersController] init completed');
  }

  Future<void> dispose() async {
    _epoch++;
    if (_opLock != null && !_opLock!.isCompleted) {
      _opLock!.complete();
    }
    _opLock = null;
    try {
      await _mgr?.deleteAll();
    } catch (_) {}
    _mgr = null;
    _byKey.clear();
  }

  Future<void> clear() async {
    final mgr = _mgr;
    if (mgr == null) return;
    _epoch++;
    _byKey.clear();
    try {
      await mgr.deleteAll();
    } catch (_) {}
  }

  String _key(RouteMapWaypoint w) => '${w.day}_${w.order}_${w.name}';

  Future<Uint8List> _iconForWaypoint(
    RouteMapWaypoint w,
    bool isLight,
    int displayOrder,
  ) async {
    final key = '${w.day}_${w.order}_${w.unavailable}_${displayOrder}_$isLight';
    final hit = _routeIconCache[key];
    if (hit != null) {
      return hit;
    }
    final bytes = await RouteStopBitmapBuilder.bitmapForOrder(
      displayOrder,
      unavailable: w.unavailable,
      isLight: isLight,
    );
    _routeIconCache[key] = bytes;
    return bytes;
  }

  Future<void> setWaypoints(
    List<RouteMapWaypoint> waypoints, {
    required bool isLight,
  }) async {
    final mgr = _mgr;
    if (mgr == null) return;
    final epoch = ++_epoch;

    await (_opLock?.future ?? Future.value());
    final lock = Completer<void>();
    _opLock = lock;

    try {
      if (epoch != _epoch) return;

      await mgr.deleteAll();
      _byKey.clear();

      final options = <mb.PointAnnotationOptions>[];
      for (var i = 0; i < waypoints.length; i++) {
        final w = waypoints[i];
        // Web MapPage uses list index + 1, not raw order (backend may send order 0).
        final displayOrder = i + 1;
        options.add(
          mb.PointAnnotationOptions(
            geometry: mb.Point(
              coordinates: mb.Position(w.longitude, w.latitude),
            ),
            image: await _iconForWaypoint(w, isLight, displayOrder),
            iconAnchor: mb.IconAnchor.CENTER,
            iconSize: 1.0,
            symbolSortKey: 1000.0 + i,
          ),
        );
        if (epoch != _epoch) return;
      }

      if (epoch != _epoch) return;
      final created = await mgr.createMulti(options);
      for (var i = 0; i < created.length && i < waypoints.length; i++) {
        final ann = created[i];
        if (ann != null) {
          _byKey[_key(waypoints[i])] = ann;
        }
      }
      log('[RouteMarkersController] setWaypoints count=${waypoints.length}');
    } catch (e, st) {
      log('[RouteMarkersController] setWaypoints failed: $e\n$st');
    } finally {
      if (!lock.isCompleted) {
        lock.complete();
      }
      if (identical(_opLock, lock)) _opLock = null;
    }
  }
}
