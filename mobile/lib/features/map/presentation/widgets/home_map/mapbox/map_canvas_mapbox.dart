import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:mobile/core/config/mapbox_config.dart';
import 'package:mobile/features/poi_search/data/api/poi_search_dto_debug.dart';

import '../../../../../poi_search/data/models/poi.dart';

import '../../../../../poi_search/presentation/binders/area_poi_search_sync.dart';
import '../../../../../poi_search/presentation/bloc/area_query_bloc.dart';
import '../../../../../poi_search/presentation/bloc/area_query_event.dart';

import '../../../../../poi_search/presentation/bloc/poi_search_bloc.dart';
import '../../../../../poi_search/presentation/bloc/poi_search_event.dart' hide ViewportChanged;

import '../../../../data/models/map_view_mode.dart';
import '../../../bloc/map_bloc.dart';
import '../../../bloc/map_event.dart';
import '../../../bloc/map_state.dart';

import '../drawing/map_drawing_overlay.dart';
import '../markers/poi_markers_controller.dart';
import '../markers/poi_markers_listener.dart';
import 'mapbox_view.dart';

class MapCanvasMapbox extends StatefulWidget {
  const MapCanvasMapbox({super.key});

  @override
  State<MapCanvasMapbox> createState() => _MapCanvasMapboxState();
}

class _MapCanvasMapboxState extends State<MapCanvasMapbox> {
  mb.MapboxMap? _map;

  /// VACANZA-197: marker controller
  PoiMarkersController? _poiMarkers;

  @override
  void dispose() {
    _poiMarkers?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      ],
      child: Stack(
        children: [
          // =====================================================
          // 1) MAP + VIEWPORT -> AreaQueryBloc
          // =====================================================
          MapboxView(
            ignoreGestures: isDrawing,
            onMapCreated: _onMapCreated,
            onViewportBbox: (bbox) {
              // Viewport bbox değişince AreaQueryBloc güncelliyoruz.
              context.read<AreaQueryBloc>().add(ViewportChanged(bbox));
            },
          ),

          // =====================================================
          // 2) AreaQueryBloc -> PoiSearchBloc SYNC (YENİ)
          //    Bu yoksa split sonrası PoiSearch hiç tetiklenmez.
          // =====================================================
          const AreaPoiSearchSync(),

          // =====================================================
          // 3) POI SEARCH -> MARKERS
          //    Not: _poiMarkers init olunca setState yapıyoruz,
          //    yoksa listener hep null görüp hiçbir şey çizmez.
          // =====================================================
          PoiMarkersListener(
            poiMarkers: _poiMarkers,
            // Backend boş dönünce mock göstermek için açık.
            // Backend düzgün dönmeye başlayınca false yapabiliriz.
            useMockWhenBackendEmpty: true,
            mockPois: _mockPoisNearCenter,
          ),

          // =====================================================
          // 4) DRAWING OVERLAY -> AreaQueryBloc (USER_SELECTION)
          // =====================================================
          MapDrawingOverlay(
            isDrawing: isDrawing,
            map: _map,
            onPolygonFinished: (polygon) {
              // Kullanıcı polygon çizince AreaQueryBloc userSelection’a geçer.
              context.read<AreaQueryBloc>().add(UserSelectionChanged(polygon));
            },
            onDisableDrawing: () {
              context.read<MapBloc>().add(SetDrawingEnabled(false));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onMapCreated(mb.MapboxMap mapboxMap) async {
    _map = mapboxMap;

    // Debug log (request/response formatını gör)
    debugPoiSearchDto();

    // İlk açılış: 2D
    await _applyViewMode(MapViewMode.mode2D);

    // Marker controller init
    final controller = PoiMarkersController(mapboxMap);
    await controller.init();

    // ÖNEMLİ:
    // Split sonrası listener'a "non-null controller" ile rebuild yaptırmak için setState şart.
    if (!mounted) return;
    setState(() {
      _poiMarkers = controller;
    });

    // Map initialized event
    context.read<MapBloc>().add(MapInitialized(mapboxMap));

    if (kDebugMode) {
      debugPrint('[MapCanvasMapbox] Map created, marker controller ready.');
    }
  }

  // ----------------------------------------------------------
  // Map style + camera
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

  // ----------------------------------------------------------
  // Mock POI listesi (backend boşken marker görmek için)
  // ----------------------------------------------------------
  List<Poi> _mockPoisNearCenter() {
    return const <Poi>[
      Poi(
        poiId: 'mock_1',
        name: 'Cafe A',
        category: 'cafe',
        latitude: 39.93,
        longitude: 32.86,
      ),
      Poi(
        poiId: 'mock_2',
        name: 'Museum A',
        category: 'museum',
        latitude: 39.931,
        longitude: 32.861,
      ),
      Poi(
        poiId: 'mock_3',
        name: 'Park A',
        category: 'parks',
        latitude: 39.932,
        longitude: 32.862,
      ),
      Poi(
        poiId: 'mock_4',
        name: 'Restaurant A',
        category: 'restaurants',
        latitude: 39.933,
        longitude: 32.863,
      ),
      Poi(
        poiId: 'mock_5',
        name: 'Monument A',
        category: 'monuments',
        latitude: 39.934,
        longitude: 32.864,
      ),
    ];
  }
}