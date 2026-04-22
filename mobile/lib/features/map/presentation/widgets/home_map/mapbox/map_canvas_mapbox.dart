import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import '../../../../../poi_search/data/models/area_source.dart';
import '../../../../../poi_search/data/models/selected_area.dart';
import '../../../../../poi_search/presentation/bloc/area_query_bloc.dart';
import '../../../../../poi_search/presentation/bloc/area_query_event.dart'
    as aq;
import '../../../../../poi_search/presentation/bloc/area_query_state.dart';
import '../../../../../poi_search/presentation/bloc/poi_search_bloc.dart';
import '../../../../../poi_search/presentation/bloc/poi_search_state.dart';

import '../../../../data/models/map_basemap.dart';
import '../../../../data/models/map_perspective.dart';
import '../../../bloc/map_bloc.dart';
import '../../../bloc/map_event.dart';
import '../../../bloc/map_state.dart';

import '../../../../../checkin/presentation/bloc/location_bloc.dart';
import '../../../../../checkin/presentation/bloc/location_state.dart';

import '../drawing/map_drawing_overlay.dart';
import '../../../../../poi_search/data/models/poi.dart';
import '../markers/poi_marker_detail_sheet.dart';
import '../markers/poi_markers_controller.dart';
import '../markers/poi_markers_listener.dart';
import '../markers/route_markers_controller.dart';
import 'mapbox_view.dart';
import 'package:mobile/core/config/mapbox_config.dart';
import '../../../../../poi_search/data/services/style_poi_discovery_binding.dart';
import 'package:mobile/features/ai/presentation/cubit/active_route_cubit.dart';
import 'package:mobile/features/ai/presentation/cubit/active_route_state.dart';
import 'package:mobile/features/ai/utils/route_map.dart';
import 'package:mobile/features/ai/data/api/ai_route_api_client.dart';

class MapCanvasMapbox extends StatefulWidget {
  const MapCanvasMapbox({super.key});

  @override
  State<MapCanvasMapbox> createState() => _MapCanvasMapboxState();
}

class _MapCanvasMapboxState extends State<MapCanvasMapbox> {
  mb.MapboxMap? _map;
  PoiMarkersController? _poiMarkers;
  RouteMarkersController? _routeMarkers;
  mb.PolylineAnnotationManager? _routeLineMgr;
  StylePoiDiscoveryBinding? _styleBinding;

  String? _lastStyleUri;

  bool _suspendViewportUpdates = false;
  Timer? _resumeTimer;

  int _selectionRebuildTick = 0;
  int _markerControllerKey = 0;

  /// Son senkronlanan uygulama parlaklığı (tema değişince harita basemap güncellenir).
  Brightness? _lastSyncedAppBrightness;

  /// Tema değişince rota marker bitmap + polyline renklerini yenile.
  Brightness? _lastRouteThemeBrightness;

  /// Yarışan GET/POST directions yanıtlarını yok say.
  int _directionsEpoch = 0;

  static String _styleUriForBasemap(MapBasemap basemap) {
    return switch (basemap) {
      MapBasemap.streets => MapboxConfig.styleStandard,
      MapBasemap.dark => MapboxConfig.styleDark,
      MapBasemap.satellite => MapboxConfig.styleStandardSatellite,
    };
  }

  /// Map is shown only when we have coordinates or a definitive non-tracking
  /// outcome (denied / error); otherwise a spinner until GPS or last-known seed.
  static bool _locationAllowsMap(LocationState loc) {
    if (loc.latitude != null && loc.longitude != null) return true;
    switch (loc.status) {
      case LocationStatus.permissionDenied:
      case LocationStatus.permissionDeniedForever:
      case LocationStatus.error:
        return true;
      case LocationStatus.initial:
      case LocationStatus.tracking:
        return false;
    }
  }

  static mb.CameraOptions _cameraForLocation(LocationState loc) {
    if (loc.latitude != null && loc.longitude != null) {
      return mb.CameraOptions(
        center: mb.Point(
          coordinates: mb.Position(loc.longitude!, loc.latitude!),
        ),
        zoom: 15.0,
        pitch: 0,
        bearing: 0,
      );
    }
    return MapboxConfig.initialCamera;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _styleBinding = context.read<StylePoiDiscoveryBinding>();

    final b = Theme.of(context).brightness;
    if (_lastSyncedAppBrightness != b) {
      _lastSyncedAppBrightness = b;
      context.read<MapBloc>().add(
        SyncBasemapToAppTheme(isDark: b == Brightness.dark),
      );
    }
    final prevRt = _lastRouteThemeBrightness;
    _lastRouteThemeBrightness = b;
    if (prevRt != null && prevRt != b) {
      unawaited(_applyActiveRouteToMap());
    }
  }

  @override
  void dispose() {
    _resumeTimer?.cancel();
    _styleBinding?.detachMap();
    unawaited(_poiMarkers?.dispose());
    unawaited(_routeMarkers?.dispose());
    unawaited(_routeLineMgr?.deleteAll());
    super.dispose();
  }

  void _onPoiMarkerTapped(Poi poi) {
    if (!mounted) return;
    showPoiMarkerDetailSheet(context, poi);
  }

  void _suspendViewportFor({required int ms}) {
    _resumeTimer?.cancel();
    _suspendViewportUpdates = true;

    _resumeTimer = Timer(Duration(milliseconds: ms), () {
      if (!mounted) return;
      _suspendViewportUpdates = false;
      unawaited(_emitCurrentViewportBbox());
    });
  }

  Future<void> _emitCurrentViewportBbox() async {
    final map = _map;
    if (map == null) return;
    if (!mounted) return;

    try {
      final cs = await map.getCameraState();
      final cb = await map.coordinateBoundsForCamera(
        mb.CameraOptions(
          center: cs.center,
          zoom: cs.zoom,
          bearing: cs.bearing,
          pitch: cs.pitch,
        ),
      );

      final sw = cb.southwest.coordinates;
      final ne = cb.northeast.coordinates;

      final bbox = BboxArea(
        minLat: (sw[1] as num).toDouble(),
        minLng: (sw[0] as num).toDouble(),
        maxLat: (ne[1] as num).toDouble(),
        maxLng: (ne[0] as num).toDouble(),
      );

      if (!mounted) return;
      final areaCtx = context.read<AreaQueryBloc>().state.context;
      if (areaCtx.areaSource == AreaSource.userSelection) return;

      context.read<AreaQueryBloc>().add(aq.ViewportChanged(bbox));
      log('[MapCanvas] Viewport bbox re-emitted after suspend');
    } catch (e) {
      log('[MapCanvas] _emitCurrentViewportBbox failed: $e');
    }
  }

  // ── Native location puck (minimal settings) ───────────────────────

  Future<void> _enableLocationPuck(mb.MapboxMap map) async {
    try {
      await map.location.updateSettings(
        mb.LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          showAccuracyRing: true,
          puckBearingEnabled: true,
        ),
      );
      log('[MapCanvas] Location puck enabled (minimal)');
    } catch (e, st) {
      log('[MapCanvas] Location puck failed: $e\n$st');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bool isDrawing = context.select((MapBloc b) => b.state.isDrawing);

    final LocationState locState = context.watch<LocationBloc>().state;
    final bool showMap = _locationAllowsMap(locState);

    final AreaQueryState areaState = context.watch<AreaQueryBloc>().state;
    final areaCtx = areaState.context;

    final PolygonArea? activeSelectionPolygon =
        (areaCtx.areaSource == AreaSource.userSelection &&
                areaCtx.area is PolygonArea)
            ? (areaCtx.area as PolygonArea)
            : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (w.isFinite && h.isFinite && w >= 16 && h >= 16) {
          _styleBinding?.updateViewportSize(Size(w, h));
        }

        return MultiBlocListener(
          listeners: [
            // ── Basemap / perspective (web: STYLES × is3D) ────────────
            BlocListener<MapBloc, MapState>(
              listenWhen:
                  (prev, next) =>
                      prev.basemap != next.basemap ||
                      prev.perspective != next.perspective,
              listener: (context, state) async {
                final map = _map;
                if (map == null) return;

                final poiBloc = context.read<PoiSearchBloc>();

                log(
                  '[MapCanvas] Map display → basemap=${state.basemap.label} '
                  'perspective=${state.perspective.label}',
                );

                _suspendViewportFor(ms: 900);

                final bool styleChanged = await _applyMapVisuals(
                  state.basemap,
                  state.perspective,
                );

                if (styleChanged) {
                  log(
                    '[MapCanvas] Style changed -> recreating PoiMarkersController',
                  );

                  final oldController = _poiMarkers;
                  if (oldController != null) {
                    await oldController.dispose();
                  }
                  final oldRoute = _routeMarkers;
                  if (oldRoute != null) {
                    await oldRoute.dispose();
                  }
                  if (_routeLineMgr != null) {
                    try {
                      await _routeLineMgr!.deleteAll();
                    } catch (_) {}
                    _routeLineMgr = null;
                  }

                  _routeLineMgr =
                      await map.annotations.createPolylineAnnotationManager();

                  final newController = PoiMarkersController(
                    map,
                    onPoiTap: _onPoiMarkerTapped,
                  );
                  await newController.init();

                  if (!newController.isReady) {
                    log(
                      '[MapCanvas] PoiMarkersController init failed after style change',
                    );
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

                  log(
                    '[MapCanvas] New controller created key=$_markerControllerKey',
                  );

                  final poiState = poiBloc.state;

                  if (poiState.status == PoiSearchStatus.success &&
                      poiState.pois.isNotEmpty) {
                    log(
                      '[MapCanvas] Reapplying ${poiState.pois.length} POIs to new controller',
                    );
                    await newController.setPois(poiState.pois);
                  } else {
                    await newController.clear();
                  }

                  final routeMarkers = RouteMarkersController(map);
                  await routeMarkers.init();
                  _routeMarkers = routeMarkers;
                  unawaited(_applyActiveRouteToMap());
                }

                // Re-enable puck after style change
                if (mounted) {
                  await _enableLocationPuck(map);
                }
              },
            ),

            // ── ActiveRoute: markers + polyline per active day ──────────
            BlocListener<ActiveRouteCubit, ActiveRouteState>(
              listenWhen:
                  (prev, next) =>
                      prev.status != next.status ||
                      prev.activeDay != next.activeDay ||
                      prev.route != next.route ||
                      prev.showRouteOnMap != next.showRouteOnMap,
              listener: (context, state) {
                unawaited(_applyActiveRouteToMap());
              },
            ),

            // ── Route kapandıktan sonra viewport'u yenile ─────────────
            BlocListener<MapBloc, MapState>(
              listenWhen: (prev, next) =>
                  prev.refreshViewportTick != next.refreshViewportTick,
              listener: (context, state) {
                unawaited(_emitCurrentViewportBbox());
              },
            ),

            // ── Recenter → fly to latest GPS position (MOB-6) ────────
            BlocListener<MapBloc, MapState>(
              listenWhen:
                  (prev, next) => prev.recenterTick != next.recenterTick,
              listener: (context, state) async {
                final map = _map;
                if (map == null) return;

                final loc = context.read<LocationBloc>().state;

                if (loc.latitude == null || loc.longitude == null) {
                  log('[MapCanvas] Recenter — no GPS fix yet');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Location not available'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                log(
                  '[MapCanvas] Recenter to GPS lat=${loc.latitude} lng=${loc.longitude}',
                );
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

            // ── POI sheet: "Show on map" → fly to POI ─────────────────
            BlocListener<MapBloc, MapState>(
              listenWhen:
                  (prev, next) => prev.flyToPoiTick != next.flyToPoiTick,
              listener: (context, state) async {
                final map = _map;
                final lat = state.flyToPoiLat;
                final lng = state.flyToPoiLng;
                if (map == null || lat == null || lng == null) return;

                log(
                  '[MapCanvas] FlyToPoi lat=$lat lng=$lng zoom=${state.flyToPoiZoom}',
                );
                // Longer suspend than default: route sheet taps + camera fly used to
                // thrash viewport-driven POI reloads and relayout (sheet felt like it “collapsed”).
                _suspendViewportFor(ms: 1400);

                await map.flyTo(
                  mb.CameraOptions(
                    center: mb.Point(coordinates: mb.Position(lng, lat)),
                    zoom: state.flyToPoiZoom,
                    pitch: 0,
                    bearing: 0,
                  ),
                  mb.MapAnimationOptions(duration: 600, startDelay: 0),
                );
              },
            ),

            // ── Fit entire route in view (padding for bottom sheet / chrome) ─
            BlocListener<MapBloc, MapState>(
              listenWhen:
                  (prev, next) => prev.fitRouteTick != next.fitRouteTick,
              listener: (context, state) async {
                final map = _map;
                final minLat = state.fitRouteMinLat;
                final maxLat = state.fitRouteMaxLat;
                final minLng = state.fitRouteMinLng;
                final maxLng = state.fitRouteMaxLng;
                if (map == null ||
                    minLat == null ||
                    maxLat == null ||
                    minLng == null ||
                    maxLng == null) {
                  return;
                }

                final mq = MediaQuery.of(context);
                final h = mq.size.height;
                // Too much bottom padding makes the camera zoom out excessively.
                // Keep room for route sheet but clamp the zoom impact.
                final padBottom = h * 0.30 + mq.padding.bottom + 16;
                final padTop = mq.padding.top + 88;
                final padH = 20.0;

                log(
                  '[MapCanvas] FitRouteBounds '
                  'lat=[$minLat,$maxLat] lng=[$minLng,$maxLng] bearing=${state.fitRouteBearing}',
                );
                _suspendViewportFor(ms: 1200);

                try {
                  final bounds = mb.CoordinateBounds(
                    southwest: mb.Point(
                      coordinates: mb.Position(minLng, minLat),
                    ),
                    northeast: mb.Point(
                      coordinates: mb.Position(maxLng, maxLat),
                    ),
                    infiniteBounds: false,
                  );
                  final padding = mb.MbxEdgeInsets(
                    top: padTop,
                    left: padH,
                    bottom: padBottom,
                    right: padH,
                  );
                  final camera = await map.cameraForCoordinateBounds(
                    bounds,
                    padding,
                    state.fitRouteBearing,
                    0,
                    16.5,
                    null,
                  );
                  await map.easeTo(
                    camera,
                    mb.MapAnimationOptions(duration: 900, startDelay: 0),
                  );
                } catch (e, st) {
                  log('[MapCanvas] FitRouteBounds failed: $e\n$st');
                  final midLat = (minLat + maxLat) / 2;
                  final midLng = (minLng + maxLng) / 2;
                  final latSpan = (maxLat - minLat).abs().clamp(0.001, 20.0);
                  final lngSpan = (maxLng - minLng).abs().clamp(0.001, 40.0);
                  final span = math.max(latSpan, lngSpan * 0.8);
                  final zoomGuess = (13.5 - span * 80).clamp(9.0, 15.0);
                  await map.easeTo(
                    mb.CameraOptions(
                      center: mb.Point(
                        coordinates: mb.Position(midLng, midLat),
                      ),
                      zoom: zoomGuess,
                      pitch: 0,
                      bearing: state.fitRouteBearing ?? 0,
                    ),
                    mb.MapAnimationOptions(duration: 800, startDelay: 0),
                  );
                }
              },
            ),
          ],
          child:
              !showMap
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                    children: [
                      Positioned.fill(
                        child: MapboxView(
                          ignoreGestures: isDrawing,
                          cameraOptions: _cameraForLocation(locState),
                          mapWidgetKey: ValueKey(
                            'map-${locState.latitude != null && locState.longitude != null ? 'gps' : 'nogps'}-${locState.status}',
                          ),
                          onMapCreated: _onMapCreated,
                          onMapIdle: () {
                            if (_map == null) return;
                            if (isDrawing) return;

                            final ctx =
                                context.read<AreaQueryBloc>().state.context;
                            if (ctx.areaSource != AreaSource.userSelection) {
                              return;
                            }
                            if (ctx.area is! PolygonArea) return;

                            if (!mounted) return;
                            setState(() => _selectionRebuildTick++);
                          },
                          onViewportBbox: (bbox) {
                            if (_suspendViewportUpdates) return;

                            final ctx =
                                context.read<AreaQueryBloc>().state.context;
                            if (ctx.areaSource == AreaSource.userSelection) {
                              return;
                            }

                            context.read<AreaQueryBloc>().add(
                              aq.ViewportChanged(bbox),
                            );
                          },
                        ),
                      ),

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
                          context.read<AreaQueryBloc>().add(
                            aq.UserSelectionChanged(polygon),
                          );
                          context.read<MapBloc>().add(SetDrawingEnabled(false));
                        },
                      ),
                    ],
                  ),
        );
      },
    );
  }

  List<mb.Position>? _parseDirectionsCoordinates(Map<String, dynamic> data) {
    final raw = data['coordinates'];
    if (raw is! List || raw.length < 2) {
      return null;
    }
    final out = <mb.Position>[];
    for (final item in raw) {
      if (item is Map) {
        final lat = item['latitude'] ?? item['lat'];
        final lng = item['longitude'] ?? item['lng'] ?? item['lon'];
        if (lat is num && lng is num) {
          out.add(mb.Position(lng.toDouble(), lat.toDouble()));
        }
      }
    }
    return out.length >= 2 ? out : null;
  }

  Future<void> _applyActiveRouteToMap() async {
    final map = _map;
    if (map == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    final isLight = Theme.of(context).brightness == Brightness.light;
    final routeApi = context.read<AiRouteApiClient>();
    final routeState = context.read<ActiveRouteCubit>().state;
    final markers = _routeMarkers;
    final lineMgr = _routeLineMgr;
    if (markers == null || lineMgr == null) {
      return;
    }

    if (routeState.status != ActiveRouteStatus.ready ||
        routeState.route == null ||
        !routeState.showRouteOnMap) {
      await markers.clear();
      try {
        await lineMgr.deleteAll();
      } catch (_) {}
      return;
    }

    final day = routeState.activeDay;
    final dayModel = routeState.route!.days
        .where((d) => d.day == day)
        .toList(growable: false);
    final typed =
        dayModel.isNotEmpty ? dayModel.first.waypoints : <RouteMapWaypoint>[];
    final lineEpoch = ++_directionsEpoch;

    await markers.setWaypoints(typed, isLight: isLight);

    try {
      await lineMgr.deleteAll();
      if (typed.length < 2) {
        return;
      }
      final lineColor =
          isLight ? const Color(0xFFFF6B6B) : const Color(0xFF38BDF8);

      List<mb.Position>? pathPositions;
      try {
        final res = await routeApi.getDirectionsGeometry(
          waypoints:
              typed
                  .map(
                    (w) => <String, dynamic>{
                      'latitude': w.latitude,
                      'longitude': w.longitude,
                    },
                  )
                  .toList(growable: false),
        );
        if (!mounted || lineEpoch != _directionsEpoch) {
          return;
        }
        pathPositions = _parseDirectionsCoordinates(res);
      } catch (e, st) {
        log('[MapCanvas] directions geometry failed, using straight: $e\n$st');
      }

      final coords =
          (pathPositions != null && pathPositions.length >= 2)
              ? pathPositions
              : typed
                  .map((w) => mb.Position(w.longitude, w.latitude))
                  .toList(growable: false);

      if (!mounted || lineEpoch != _directionsEpoch) {
        return;
      }
      await lineMgr.create(
        mb.PolylineAnnotationOptions(
          geometry: mb.LineString(coordinates: coords),
          lineColor: lineColor.toARGB32(),
          lineWidth: 5.0,
          lineOpacity: 0.85,
        ),
      );
    } catch (e) {
      log('[MapCanvas] route polyline failed: $e');
    }
  }

  // ── Map init ───────────────────────────────────────────────────────

  Future<void> _onMapCreated(mb.MapboxMap mapboxMap) async {
    _map = mapboxMap;
    _styleBinding?.attachMap(mapboxMap);

    log('[MapCanvas] Map created');

    // Jump to GPS location instantly if already available.
    if (mounted) {
      final loc = context.read<LocationBloc>().state;
      if (loc.latitude != null && loc.longitude != null) {
        await mapboxMap.setCamera(
          mb.CameraOptions(
            center: mb.Point(
              coordinates: mb.Position(loc.longitude!, loc.latitude!),
            ),
            zoom: 15.0,
            pitch: 0,
            bearing: 0,
          ),
        );
        log(
          '[MapCanvas] Camera set to GPS: lat=${loc.latitude}, lng=${loc.longitude}',
        );
      }
    }

    if (!mounted) return;
    final ms = context.read<MapBloc>().state;
    await _applyMapVisuals(ms.basemap, ms.perspective);

    // Annotation order: polyline (bottom) → POI markers → route stop markers (top).
    _routeLineMgr =
        await mapboxMap.annotations.createPolylineAnnotationManager();

    final controller = PoiMarkersController(
      mapboxMap,
      onPoiTap: _onPoiMarkerTapped,
    );
    await controller.init();

    if (!controller.isReady) {
      log('[MapCanvas] PoiMarkersController init failed on map created');
      return;
    }

    if (mounted) {
      setState(() => _poiMarkers = controller);
    } else {
      _poiMarkers = controller;
    }

    final routeMarkers = RouteMarkersController(mapboxMap);
    await routeMarkers.init();
    _routeMarkers = routeMarkers;

    if (mounted) {
      context.read<MapBloc>().add(MapInitialized(mapboxMap));
    }

    // Native location puck AFTER annotation manager is fully set up.
    await _enableLocationPuck(mapboxMap);

    log('[MapCanvas] Initialization complete');
  }

  // ── Basemap (streets / dark / sat) + 2D/3D ─────────────────────────

  Future<bool> _applyMapVisuals(
    MapBasemap basemap,
    MapPerspective perspective,
  ) async {
    final map = _map;
    if (map == null) return false;

    final targetStyleUri = _styleUriForBasemap(basemap);

    final cs = await map.getCameraState();

    bool styleChanged = false;

    if (_lastStyleUri != targetStyleUri) {
      log('[MapCanvas] Loading new style: $targetStyleUri');
      await map.loadStyleURI(targetStyleUri);
      _lastStyleUri = targetStyleUri;
      styleChanged = true;
    }

    final bool enable3D = perspective == MapPerspective.mode3D;

    await _toggle3DBuildings(map, enable3D);

    final double targetPitch = enable3D ? MapboxConfig.pitch3D : 0;
    final double targetZoom =
        enable3D ? math.max(cs.zoom, MapboxConfig.zoomMin3D) : cs.zoom;

    await map.easeTo(
      mb.CameraOptions(
        center: cs.center,
        padding: cs.padding,
        zoom: targetZoom,
        pitch: targetPitch,
        bearing: cs.bearing,
      ),
      mb.MapAnimationOptions(duration: 450, startDelay: 0),
    );

    return styleChanged;
  }

  static const String _buildingLayerId = '3d-buildings';

  Future<void> _toggle3DBuildings(mb.MapboxMap map, bool enable) async {
    try {
      if (!enable) {
        final exists = await map.style.styleLayerExists(_buildingLayerId);
        if (exists) {
          await map.style.removeStyleLayer(_buildingLayerId);
        }
        return;
      }

      final exists = await map.style.styleLayerExists(_buildingLayerId);
      if (exists) return;

      final layer = mb.FillExtrusionLayer(
        id: _buildingLayerId,
        sourceId: 'composite',
      );
      layer.sourceLayer = 'building';
      layer.minZoom = 13;
      layer.fillExtrusionColor = const Color(0xFFAAAAAA).toARGB32();
      layer.fillExtrusionOpacity = 0.65;

      await map.style.addLayer(layer);

      await map.style.setStyleLayerProperty(_buildingLayerId, 'filter', [
        '==',
        ['get', 'extrude'],
        'true',
      ]);
      await map.style.setStyleLayerProperty(
        _buildingLayerId,
        'fill-extrusion-height',
        ['get', 'height'],
      );
      await map.style.setStyleLayerProperty(
        _buildingLayerId,
        'fill-extrusion-base',
        ['get', 'min_height'],
      );

      log('[MapCanvas] 3D buildings layer added');
    } catch (e) {
      log('[MapCanvas] _toggle3DBuildings failed: $e');
    }
  }
}
