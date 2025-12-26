import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'package:mobile/core/config/mapbox_config.dart';
import '../../../../poi_search/data/models/selected_area.dart';
import '../../../../poi_search/presentation/bloc/area_query_bloc.dart';
import '../../../../poi_search/presentation/bloc/area_query_event.dart';
import '../../../data/models/map_view_mode.dart';

import '../../bloc/map_bloc.dart';
import '../../bloc/map_event.dart';
import '../../bloc/map_state.dart';

class MapCanvasMapbox extends StatefulWidget {
  const MapCanvasMapbox({super.key});

  @override
  State<MapCanvasMapbox> createState() => _MapCanvasMapboxState();
}

class _MapCanvasMapboxState extends State<MapCanvasMapbox> {
  MapboxMap? _map;

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
    return BlocListener<MapBloc, MapState>(
      listenWhen: (prev, next) =>
      prev.viewMode != next.viewMode ||
          prev.recenterTick != next.recenterTick,
      listener: (context, state) async {
        if (_map == null) return;

        // ✅ Mode değişince style + config + camera uygula
        await _applyViewMode(state.viewMode);

        // ✅ Recenter tetiklendiyse preset kameraya dön
        if (state.recenterTick != 0) {
          await _recenter(state.viewMode);
        }
      },
      child: MapWidget(
        key: const ValueKey('mapbox-map'),
        cameraOptions: MapboxConfig.initialCamera,
        styleUri: MapboxConfig.styleStandard,
        onMapCreated: (mapboxMap) async {
          _map = mapboxMap;

          // İlk açılışta: 2D varsay
          await _applyViewMode(MapViewMode.mode2D);

          // Bloc'a controller hazır sinyali
          if (mounted) {
            context.read<MapBloc>().add(MapInitialized(mapboxMap));
          }
        },

        // ✅ VACANZA-200:
        // - İlk açılışta 1 kere bbox üret
        // - Pan/zoom bitince debounce ile bbox üret
        onMapIdleListener: (_) {
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

  // ----------------------------------------------------------
  // VACANZA-200: Viewport BBOX + Debounce
  // ----------------------------------------------------------

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
    context.read<AreaQueryBloc>().add(ViewportChanged(bbox));
  }

  Future<BboxArea?> _computeViewportBbox() async {
    try {
      if (_map == null) return null;

      // 1) Şu anki kamerayı al
      final cs = await _map!.getCameraState();

      // 2) Bu kamera için viewport bounds hesapla
      final CoordinateBounds cb = await _map!.coordinateBoundsForCamera(
        CameraOptions(
          center: cs.center,
          zoom: cs.zoom,
          bearing: cs.bearing,
          pitch: cs.pitch,
        ),
      );

      // 3) CoordinateBounds -> SW/NE (lng, lat)
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

  // ----------------------------------------------------------
  // Existing: View Mode / Camera
  // ----------------------------------------------------------

  Future<void> _applyViewMode(MapViewMode mode) async {
    if (_map == null) return;

    final String styleUri = (mode == MapViewMode.satellite)
        ? MapboxConfig.styleStandardSatellite
        : MapboxConfig.styleStandard;

    await _map!.loadStyleURI(styleUri);

    final bool enable3D = (mode == MapViewMode.mode3D);

    if (styleUri == MapboxConfig.styleStandard) {
      await _map!.style.setStyleImportConfigProperties(
        "basemap",
        <String, Object>{"show3dObjects": enable3D},
      );
    }

    final CameraOptions camera =
    enable3D ? MapboxConfig.camera3D : MapboxConfig.camera2D;

    await _map!.easeTo(
      camera,
      MapAnimationOptions(duration: 450, startDelay: 0),
    );
  }

  Future<void> _recenter(MapViewMode mode) async {
    if (_map == null) return;

    final CameraOptions camera =
    (mode == MapViewMode.mode3D) ? MapboxConfig.camera3D : MapboxConfig.camera2D;

    await _map!.easeTo(
      camera,
      MapAnimationOptions(duration: 550, startDelay: 0),
    );
  }
}