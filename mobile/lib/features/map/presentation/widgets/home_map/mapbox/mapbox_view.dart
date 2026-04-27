// mapbox_view.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:mobile/core/config/mapbox_config.dart';

import '../../../../../poi_search/data/models/selected_area.dart';

/// Map widget + viewport bbox emitter.
///
/// Uses [onCameraChangeListener] with debounce to track viewport changes.
/// This is more reliable than relying solely on [onMapIdleListener] because
/// continuous animations (e.g. location puck pulsing) can prevent the map
/// from ever reaching idle state.
class MapboxView extends StatefulWidget {
  final bool ignoreGestures;

  /// Initial camera; use user coordinates when available so the map does not
  /// flash a world view before GPS.
  final mb.CameraOptions cameraOptions;

  /// Optional key for the underlying [mb.MapWidget] (e.g. remount when
  /// switching between fallback and user-centered camera).
  final Key? mapWidgetKey;

  final Future<void> Function(mb.MapboxMap mapboxMap) onMapCreated;

  final void Function(BboxArea bbox) onViewportBbox;

  final VoidCallback? onMapIdle;
  final VoidCallback? onCameraChange;

  const MapboxView({
    super.key,
    required this.ignoreGestures,
    required this.cameraOptions,
    this.mapWidgetKey,
    required this.onMapCreated,
    required this.onViewportBbox,
    this.onMapIdle,
    this.onCameraChange,
  });

  @override
  State<MapboxView> createState() => _MapboxViewState();
}

class _MapboxViewState extends State<MapboxView> {
  mb.MapboxMap? _map;

  Timer? _debounce;
  static const Duration _debounceDuration = Duration(milliseconds: 600);

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: widget.ignoreGestures,
      child: mb.MapWidget(
        key: widget.mapWidgetKey ?? const ValueKey('mapbox-map'),
        cameraOptions: widget.cameraOptions,
        styleUri: MapboxConfig.styleStandard,
        onMapCreated: (mapboxMap) async {
          _map = mapboxMap;
          await widget.onMapCreated(mapboxMap);
        },
        onMapIdleListener: (_) {
          if (_map == null) return;
          widget.onMapIdle?.call();
          _scheduleViewportBbox();
        },
        onCameraChangeListener: (_) {
          if (_map == null) return;
          widget.onCameraChange?.call();
          _scheduleViewportBbox();
        },
      ),
    );
  }

  void _scheduleViewportBbox() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      unawaited(_emitViewportBboxNow());
    });
  }

  Future<void> _emitViewportBboxNow() async {
    if (_map == null) return;

    final bbox = await _computeViewportBbox();
    if (bbox == null) return;

    if (!mounted) return;
    widget.onViewportBbox(bbox);
  }

  Future<BboxArea?> _computeViewportBbox() async {
    try {
      if (_map == null) return null;

      final cs = await _map!.getCameraState();

      final mb.CoordinateBounds cb = await _map!.coordinateBoundsForCamera(
        mb.CameraOptions(
          center: cs.center,
          zoom: cs.zoom,
          bearing: cs.bearing,
          pitch: cs.pitch,
        ),
      );

      final sw = cb.southwest.coordinates;
      final ne = cb.northeast.coordinates;

      final minLng = (sw[0] as num).toDouble();
      final minLat = (sw[1] as num).toDouble();
      final maxLng = (ne[0] as num).toDouble();
      final maxLat = (ne[1] as num).toDouble();

      return BboxArea(
        minLat: minLat,
        minLng: minLng,
        maxLat: maxLat,
        maxLng: maxLng,
      );
    } catch (_) {
      return null;
    }
  }
}
