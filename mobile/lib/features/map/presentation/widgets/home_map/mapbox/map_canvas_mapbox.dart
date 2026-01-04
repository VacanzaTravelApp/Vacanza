import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import '../../../../../poi_search/data/models/area_source.dart';
import '../../../../../poi_search/data/models/selected_area.dart';
import '../../../../../poi_search/presentation/bloc/area_query_bloc.dart';
import '../../../../../poi_search/presentation/bloc/area_query_event.dart' as aq;
import '../../../../../poi_search/presentation/bloc/area_query_state.dart';
import '../../../../../poi_search/presentation/bloc/poi_search_bloc.dart';
import '../../../../../poi_search/presentation/bloc/poi_search_event.dart' as ps;
import '../../../../../poi_search/presentation/bloc/poi_search_state.dart';

import '../../../../data/models/map_view_mode.dart';
import '../../../bloc/map_bloc.dart';
import '../../../bloc/map_event.dart';
import '../../../bloc/map_state.dart';

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

  @override
  void dispose() {
    _poiMarkers?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDrawing = context.select((MapBloc b) => b.state.isDrawing);

    // ✅ Single source: selection overlay AreaQuery’den gelir
    final AreaQueryState areaState = context.watch<AreaQueryBloc>().state;
    final ctx = areaState.context;

    final PolygonArea? activeSelectionPolygon =
    (ctx.areaSource == AreaSource.userSelection && ctx.area is PolygonArea)
        ? (ctx.area as PolygonArea)
        : null;

    return MultiBlocListener(
      listeners: [
        BlocListener<MapBloc, MapState>(
          listenWhen: (prev, next) =>
          prev.viewMode != next.viewMode || prev.recenterTick != next.recenterTick,
          listener: (context, state) async {
            if (_map == null) return;

            await _applyViewMode(state.viewMode);

            if (_poiMarkers != null) {
              await _poiMarkers!.reinitAfterStyleChange();

              final poiState = context.read<PoiSearchBloc>().state;
              if (poiState.status == PoiSearchStatus.success) {
                await _poiMarkers!.setPois(poiState.pois);
              } else {
                await _poiMarkers!.clear();
              }
            }

            if (state.recenterTick != 0) {
              await _recenter(state.viewMode);
            }
          },
        ),
      ],
      child: Stack(
        children: [
          MapboxView(
            ignoreGestures: isDrawing,
            onMapCreated: _onMapCreated,
            onViewportBbox: (bbox) {
              // ✅ SADECE AreaQuery’ye: tek kanal
              context.read<AreaQueryBloc>().add(aq.ViewportChanged(bbox));
            },
          ),

          PoiMarkersListener(
            poiMarkers: _poiMarkers,
          ),

          MapDrawingOverlay(
            isDrawing: isDrawing,
            map: _map,
            activeSelectionPolygon: activeSelectionPolygon,
            onPolygonFinished: (polygon) {
              // ✅ selection state
              context.read<AreaQueryBloc>().add(aq.UserSelectionChanged(polygon));

              // ✅ poi search state
              context.read<PoiSearchBloc>().add(ps.AreaChanged(polygon));

              // ✅ drawing kapat
              context.read<MapBloc>().add(SetDrawingEnabled(false));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onMapCreated(mb.MapboxMap mapboxMap) async {
    _map = mapboxMap;

    await _applyViewMode(MapViewMode.mode2D);

    final controller = PoiMarkersController(mapboxMap);
    await controller.init();

    if (mounted) {
      setState(() => _poiMarkers = controller);
    } else {
      _poiMarkers = controller;
    }

    if (mounted) {
      context.read<MapBloc>().add(MapInitialized(mapboxMap));
    }
  }

  Future<void> _applyViewMode(MapViewMode mode) async {
    final map = _map;
    if (map == null) return;

    final String styleUri = (mode == MapViewMode.satellite)
        ? MapboxConfig.styleStandardSatellite
        : MapboxConfig.styleStandard;

    await map.loadStyleURI(styleUri);

    final bool enable3D = (mode == MapViewMode.mode3D);

    if (styleUri == MapboxConfig.styleStandard) {
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
  }

  Future<void> _recenter(MapViewMode mode) async {
    final map = _map;
    if (map == null) return;

    final mb.CameraOptions camera =
    (mode == MapViewMode.mode3D) ? MapboxConfig.camera3D : MapboxConfig.camera2D;

    await map.easeTo(
      camera,
      mb.MapAnimationOptions(duration: 550, startDelay: 0),
    );
  }
}