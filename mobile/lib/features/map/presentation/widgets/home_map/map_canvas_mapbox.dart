import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:mobile/core/config/mapbox_config.dart';
import 'package:mobile/features/poi_search/data/api/poi_search_dto_debug.dart';
import '../../../../poi_search/data/models/geo_point.dart';
import '../../../../poi_search/data/models/selected_area.dart';
import '../../../../poi_search/presentation/bloc/area_query_bloc.dart';
import '../../../../poi_search/presentation/bloc/area_query_event.dart';
import '../../../data/models/map_view_mode.dart';
import '../../bloc/map_bloc.dart';
import '../../bloc/map_event.dart';
import '../../bloc/map_state.dart';
import 'freehand_painter.dart';

class MapCanvasMapbox extends StatefulWidget {
  const MapCanvasMapbox({super.key});

  @override
  State<MapCanvasMapbox> createState() => _MapCanvasMapboxState();
}

class _MapCanvasMapboxState extends State<MapCanvasMapbox> {
  mb.MapboxMap? _map;

  bool _initialViewportSent = false;

  Timer? _debounce;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  // ---------------------------
  // VACANZA-184: Freehand Polygon Drawing (UI)
  // ---------------------------
  bool _limitWarned = false;

  final List<Offset> _screenPath = [];
  final List<GeoPoint> _geoPoints = [];

  /// Finish ile kapatınca çizimin “1 an görünüp kaybolmasını” engellemek için:
  /// finish sırasında disable olunca path'i koruyoruz.
  bool _keepPathOnDisableOnce = false;

  // Pan update spam olmasın:
  DateTime _lastSampleAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _sampleEvery = Duration(milliseconds: 35);

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Drawing state MapBloc'tan
    final isDrawing = context.select((MapBloc b) => b.state.isDrawing);

    return MultiBlocListener(
      listeners: [
        // viewMode / recenter
        BlocListener<MapBloc, MapState>(
          listenWhen: (prev, next) =>
          prev.viewMode != next.viewMode ||
              prev.recenterTick != next.recenterTick,
          listener: (context, state) async {
            if (_map == null) return;

            await _applyViewMode(state.viewMode);

            if (state.recenterTick != 0) {
              await _recenter(state.viewMode);
            }
          },
        ),

        // drawing toggle
        BlocListener<MapBloc, MapState>(
          listenWhen: (prev, next) => prev.isDrawing != next.isDrawing,
          listener: (context, state) {
            _onDrawingModeChanged(state.isDrawing);
          },
        ),
      ],
      child: Stack(
        children: [
          // ================= MAP =================
          IgnorePointer(
            // Drawing ON iken map gesture almasın
            ignoring: isDrawing,
            child: mb.MapWidget(
              key: const ValueKey('mapbox-map'),
              cameraOptions: MapboxConfig.initialCamera,
              styleUri: MapboxConfig.styleStandard,
              onMapCreated: (mapboxMap) async {

                _map = mapboxMap;
                debugPoiSearchDto();
                // İlk açılışta: 2D varsay
                await _applyViewMode(MapViewMode.mode2D);

                // controller hazır
                if (mounted) {
                  context.read<MapBloc>().add(MapInitialized(mapboxMap));
                }
              },

              // ✅ VACANZA-200: viewport bbox üret
              onMapIdleListener: (_) {
                if (!_initialViewportSent) {
                  _initialViewportSent = true;
                  unawaited(_emitViewportBboxNow());
                  return;
                }
                _scheduleViewportBbox();
              },
            ),
          ),

          // ================= DRAWING OVERLAY =================
          Positioned.fill(
            child: Stack(
              children: [
                // Paint dokunma almaz
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true,
                    child: CustomPaint(
                      painter: FreehandPainter(List<Offset>.of(_screenPath)),
                    ),
                  ),
                ),

                // Gesture sadece drawing ON iken dokunma alır
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: !isDrawing,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onPanStart: (d) =>
                          unawaited(_onDrawPoint(d.localPosition)),
                      onPanUpdate: (d) =>
                          unawaited(_onDrawPoint(d.localPosition)),
                      onPanEnd: (_) => _onDrawEnd(),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // VACANZA-184: Drawing lifecycle
  // ----------------------------------------------------------

  void _onDrawingModeChanged(bool enabled) {
    if (enabled) {
      // Drawing başladı: temiz slate
      setState(() {
        _limitWarned = false;
        _screenPath.clear();
        _geoPoints.clear();
        _keepPathOnDisableOnce = false;
      });
      return;
    }

    // Drawing kapandı:
    if (_keepPathOnDisableOnce) {
      // finish sonrası: path kalsın
      _keepPathOnDisableOnce = false;
      _limitWarned = false;
      return;
    }

    // toggle ile kapatma/cancel gibi düşün: çizimi temizle
    setState(() {
      _limitWarned = false;
      _screenPath.clear();
      _geoPoints.clear();
    });
  }

  void _onDrawEnd() {
    // Parmağı kaldırınca otomatik finish/cancel
    if (_geoPoints.length >= 3) {
      final polygon = PolygonArea(List<GeoPoint>.of(_geoPoints));

      // selection state set
      context.read<AreaQueryBloc>().add(UserSelectionChanged(polygon));

      // drawing kapanırken path kaybolmasın
      _keepPathOnDisableOnce = true;

      // drawing OFF
      context.read<MapBloc>().add(SetDrawingEnabled(false));

      _geoPoints.clear();
      _limitWarned = false;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Polygon için en az 3 nokta gerekli.')),
      );

      setState(() {
        _screenPath.clear();
        _geoPoints.clear();
        _limitWarned = false;
      });

      context.read<MapBloc>().add(SetDrawingEnabled(false));
    }
  }

  Future<void> _onDrawPoint(Offset localPos) async {
    if (_map == null) return;

    // throttle
    final now = DateTime.now();
    if (now.difference(_lastSampleAt) < _sampleEvery) return;
    _lastSampleAt = now;

    // 200 nokta limiti
    if (_geoPoints.length >= 200) {
      if (!_limitWarned && mounted) {
        _limitWarned = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maksimum 200 nokta ekleyebilirsin.')),
        );
      }
      return;
    }

    // screen -> geo (önce bunu yap, null ise hiç çizme)
    final geo = await _screenToGeo(localPos);
    if (geo == null) return;

    // çok yakın noktaları şişirmemek için basit filtre
    if (_geoPoints.isNotEmpty) {
      final last = _geoPoints.last;
      final dLat = (last.lat - geo.lat).abs();
      final dLng = (last.lng - geo.lng).abs();
      if (dLat < 0.00001 && dLng < 0.00001) return;
    }

    if (!mounted) return;

    setState(() {
      _screenPath.add(localPos);
      _geoPoints.add(geo);
    });
  }

  Future<GeoPoint?> _screenToGeo(Offset localPos) async {
    try {
      if (_map == null) return null;

      final screen = mb.ScreenCoordinate(
        x: localPos.dx,
        y: localPos.dy,
      );

      final point = await _map!.coordinateForPixel(screen);

      // point.coordinates -> [lng, lat]
      final coords = point.coordinates;
      final lng = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();

      return GeoPoint(lat: lat, lng: lng);
    } catch (_) {
      return null;
    }
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

    final mb.CameraOptions camera =
    enable3D ? MapboxConfig.camera3D : MapboxConfig.camera2D;

    await _map!.easeTo(
      camera,
      mb.MapAnimationOptions(duration: 450, startDelay: 0),
    );
  }

  Future<void> _recenter(MapViewMode mode) async {
    if (_map == null) return;

    final mb.CameraOptions camera =
    (mode == MapViewMode.mode3D) ? MapboxConfig.camera3D : MapboxConfig.camera2D;

    await _map!.easeTo(
      camera,
      mb.MapAnimationOptions(duration: 550, startDelay: 0),
    );
  }
}