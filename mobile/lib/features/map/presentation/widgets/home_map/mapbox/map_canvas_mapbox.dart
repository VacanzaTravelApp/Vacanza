import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import '../../../../../poi_search/data/models/area_source.dart';
import '../../../../../poi_search/data/models/selected_area.dart';
import '../../../../../poi_search/presentation/bloc/area_query_bloc.dart';
import '../../../../../poi_search/presentation/bloc/area_query_event.dart' as aq;
import '../../../../../poi_search/presentation/bloc/area_query_state.dart';
import '../../../../../poi_search/presentation/bloc/poi_search_bloc.dart';
import '../../../../../poi_search/presentation/bloc/poi_search_state.dart';

import '../../../../data/models/map_view_mode.dart';
import '../../../bloc/map_bloc.dart';
import '../../../bloc/map_event.dart';
import '../../../bloc/map_state.dart';

import '../../../../../checkin/presentation/bloc/location_bloc.dart';
import '../../../../../checkin/presentation/bloc/location_state.dart';

import '../drawing/map_drawing_overlay.dart';
import '../markers/poi_markers_controller.dart';
import '../markers/poi_markers_listener.dart';
import 'mapbox_view.dart';
import 'package:mobile/core/config/mapbox_config.dart';

class MapCanvasMapbox extends StatefulWidget {
  const MapCanvasMapbox({super.key});

  @override
  State<MapCanvasMapbox> createState() => _MapCanvasMapboxState();
}

class _MapCanvasMapboxState extends State<MapCanvasMapbox> {
  mb.MapboxMap? _map;
  PoiMarkersController? _poiMarkers;

  /// en son yüklenen style
  String? _lastStyleUri;

  /// mode switch / recenter sırasında viewport bbox event'lerini dondur
  bool _suspendViewportUpdates = false;

  Timer? _resumeTimer;

  /// Map idle oldukça (user selection varsa) polygon screen path'i rebuild etmek için tick
  int _selectionRebuildTick = 0;

  /// Annotation manager yeniden oluşturulunca widget tree'yi rebuild etmek için key
  int _markerControllerKey = 0;

  @override
  void dispose() {
    _resumeTimer?.cancel();
    unawaited(_poiMarkers?.dispose()); // unawaited
    super.dispose();
  }

  void _suspendViewportFor({required int ms}) {
    _resumeTimer?.cancel();
    _suspendViewportUpdates = true;

    _resumeTimer = Timer(Duration(milliseconds: ms), () {
      if (!mounted) return;
      _suspendViewportUpdates = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDrawing = context.select((MapBloc b) => b.state.isDrawing);

    final AreaQueryState areaState = context.watch<AreaQueryBloc>().state;
    final areaCtx = areaState.context;

    final PolygonArea? activeSelectionPolygon =
    (areaCtx.areaSource == AreaSource.userSelection && areaCtx.area is PolygonArea)
        ? (areaCtx.area as PolygonArea)
        : null;

    return MultiBlocListener(
      listeners: [
        // ViewMode değişimi
        BlocListener<MapBloc, MapState>(
          listenWhen: (prev, next) => prev.viewMode != next.viewMode,
          listener: (context, state) async {
            final map = _map;
            if (map == null) return;

            log('[MapCanvas] ViewMode changing to ${state.viewMode.label}');

            _suspendViewportFor(ms: 900);

            final bool styleChanged = await _applyViewMode(state.viewMode);

            // Style değiştiyse annotation manager'ı tamamen yeniden oluştur
            if (styleChanged) {
              log('[MapCanvas] Style changed -> recreating PoiMarkersController');

              final oldController = _poiMarkers;
              if (oldController != null) {
                await oldController.dispose();
              }

              final newController = PoiMarkersController(map);
              await newController.init();

              // ✅ init fail olduysa state'e basma
              if (!newController.isReady) {
                log('[MapCanvas] PoiMarkersController init failed after style change');
                if (!mounted) return;
                setState(() {
                  _poiMarkers = null;
                  _markerControllerKey++;
                });
                return;
              }

              if (!mounted) return;
              setState(() {
                _poiMarkers = newController;
                _markerControllerKey++;
              });

              log('[MapCanvas] New controller created key=$_markerControllerKey');

              // mevcut POI state'ini yeniden uygula (opsiyonel ama faydalı)
              final poiState = context.read<PoiSearchBloc>().state;

              if (poiState.status == PoiSearchStatus.success && poiState.pois.isNotEmpty) {
                log('[MapCanvas] Reapplying ${poiState.pois.length} POIs to new controller');
                await newController.setPois(poiState.pois);
              } else {
                await newController.clear();
              }
            }
          },
        ),

        // Recenter → fly to latest GPS position (MOB-6)
        BlocListener<MapBloc, MapState>(
          listenWhen: (prev, next) => prev.recenterTick != next.recenterTick,
          listener: (context, state) async {
            final map = _map;
            if (map == null) return;

            final loc = context.read<LocationBloc>().state;

            if (loc.latitude == null || loc.longitude == null) {
              log('[MapCanvas] Recenter — no GPS fix yet, showing fallback message');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location not available'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            log('[MapCanvas] Recenter to GPS lat=${loc.latitude} lng=${loc.longitude}');
            _suspendViewportFor(ms: 800);

            await map.flyTo(
              mb.CameraOptions(
                center: mb.Point(
                  coordinates: mb.Position(loc.longitude!, loc.latitude!),
                ),
                zoom: 15.0,
                pitch: 0,
                bearing: 0,
              ),
              mb.MapAnimationOptions(duration: 600, startDelay: 0),
            );
          },
        ),

        // ================= First GPS fix → center camera once (MOB-6) =================
        BlocListener<LocationBloc, LocationState>(
          listenWhen: (prev, next) => !prev.isFirstFix && next.isFirstFix,
          listener: (context, state) async {
            final map = _map;
            if (map == null) return;
            if (state.latitude == null || state.longitude == null) return;

            log('[MapCanvas] ★ first GPS fix — flying camera to '
                'lat=${state.latitude}, lng=${state.longitude}');

            _suspendViewportFor(ms: 800);

            await map.flyTo(
              mb.CameraOptions(
                center: mb.Point(
                  coordinates: mb.Position(
                    state.longitude!,
                    state.latitude!,
                  ),
                ),
                zoom: 15.0,
                pitch: 0,
                bearing: 0,
              ),
              mb.MapAnimationOptions(duration: 600, startDelay: 0),
            );
          },
        ),
      ],
      child: Stack(
        children: [
          MapboxView(
            ignoreGestures: isDrawing,
            onMapCreated: _onMapCreated,
            onMapIdle: () {
              if (_map == null) return;
              if (isDrawing) return;

              final ctx = context.read<AreaQueryBloc>().state.context;
              if (ctx.areaSource != AreaSource.userSelection) return;
              if (ctx.area is! PolygonArea) return;

              if (!mounted) return;
              setState(() => _selectionRebuildTick++);
            },
            onViewportBbox: (bbox) {
              if (_suspendViewportUpdates) return;

              final ctx = context.read<AreaQueryBloc>().state.context;
              if (ctx.areaSource == AreaSource.userSelection) return;

              context.read<AreaQueryBloc>().add(aq.ViewportChanged(bbox));
            },
          ),

          // Key ile listener'ı yeniden oluştur
          PoiMarkersListener(
            key: ValueKey(_markerControllerKey),
            poiMarkers: _poiMarkers,
          ),

          MapDrawingOverlay(
            isDrawing: isDrawing,
            map: _map,
            activeSelectionPolygon: activeSelectionPolygon,
            rebuildTick: _selectionRebuildTick,
            onPolygonFinished: (polygon) {
              context.read<AreaQueryBloc>().add(aq.UserSelectionChanged(polygon));
              context.read<MapBloc>().add(SetDrawingEnabled(false));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onMapCreated(mb.MapboxMap mapboxMap) async {
    _map = mapboxMap;

    log('[MapCanvas] Map created');

    _suspendViewportFor(ms: 800);

    await _applyViewMode(MapViewMode.mode2D);

    final controller = PoiMarkersController(mapboxMap);
    await controller.init();

    // ✅ init fail olduysa _poiMarkers null kalsın
    if (!controller.isReady) {
      log('[MapCanvas] PoiMarkersController init failed on map created');
      return;
    }

    if (mounted) {
      setState(() => _poiMarkers = controller);
    } else {
      _poiMarkers = controller;
    }

    if (mounted) {
      context.read<MapBloc>().add(MapInitialized(mapboxMap));
    }

    log('[MapCanvas] Initialization complete');
  }

  /// return true => style değişti (standard <-> satellite)
  Future<bool> _applyViewMode(MapViewMode mode) async {
    final map = _map;
    if (map == null) return false;

    final String targetStyleUri =
    (mode == MapViewMode.satellite) ? MapboxConfig.styleStandardSatellite : MapboxConfig.styleStandard;

    bool styleChanged = false;

    if (_lastStyleUri != targetStyleUri) {
      log('[MapCanvas] Loading new style: $targetStyleUri');
      await map.loadStyleURI(targetStyleUri);
      _lastStyleUri = targetStyleUri;
      styleChanged = true;
    }

    final bool enable3D = (mode == MapViewMode.mode3D);

    if (targetStyleUri == MapboxConfig.styleStandard) {
      await map.style.setStyleImportConfigProperties(
        "basemap",
        <String, Object>{"show3dObjects": enable3D},
      );
    }

    final mb.CameraOptions camera = enable3D ? MapboxConfig.camera3D : MapboxConfig.camera2D;

    await map.easeTo(
      camera,
      mb.MapAnimationOptions(duration: 450, startDelay: 0),
    );

    return styleChanged;
  }

}