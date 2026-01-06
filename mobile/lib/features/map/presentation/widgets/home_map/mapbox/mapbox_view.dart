// mapbox_view.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:mobile/core/config/mapbox_config.dart';

import '../../../../../poi_search/data/models/selected_area.dart';

/// Map widget + viewport bbox emitter (debounced).
/// - Gesture ignore: drawing modunda map interaction kapatmak için.
/// - İlk idle’da da bbox gönderir.
/// - ✅ Parent isterse her idle eventini dinleyebilir (selection redraw için).
class MapboxView extends StatefulWidget {
  final bool ignoreGestures;

  /// Parent map referansını saklayabilsin diye.
  final Future<void> Function(mb.MapboxMap mapboxMap) onMapCreated;

  /// Viewport bbox üretildiğinde parent’a gönderir.
  final void Function(BboxArea bbox) onViewportBbox;

  /// ✅ Map idle olduğunda parent bilgilensin (bbox dışında işler için)
  final VoidCallback? onMapIdle;

  const MapboxView({
    super.key,
    required this.ignoreGestures,
    required this.onMapCreated,
    required this.onViewportBbox,
    this.onMapIdle,
  });

  @override
  State<MapboxView> createState() => _MapboxViewState();
}

class _MapboxViewState extends State<MapboxView> {
  mb.MapboxMap? _map;

  bool _initialViewportSent = false;

  Timer? _debounce;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

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
        key: const ValueKey('mapbox-map'),
        cameraOptions: MapboxConfig.initialCamera,
        styleUri: MapboxConfig.styleStandard,
        onMapCreated: (mapboxMap) async {
          _map = mapboxMap;
          await widget.onMapCreated(mapboxMap);
        },
        onMapIdleListener: (_) {
          if (_map == null) return;

          // ✅ Parent'a idle sinyali (selection polygon redraw vb.)
          widget.onMapIdle?.call();

          if (!_initialViewportSent) {
            _initialViewportSent = true;
            unawaited(_emitViewportBboxNow());
            return;
          }

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