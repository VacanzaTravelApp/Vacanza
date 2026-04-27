import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../data/models/map_basemap.dart';
import '../../data/models/map_perspective.dart';
import 'map_event.dart';
import 'map_state.dart';

/// HomeMapScreen'deki UI state yönetimini tek yerde tutar.
class MapBloc extends Bloc<MapEvent, MapState> {
  MapboxMap? _controller;

  MapBloc() : super(MapState.initial()) {
    on<MapInitialized>(_onInitialized);
    on<CycleBasemapPressed>(_onCycleBasemap);
    on<TogglePerspectivePressed>(_onTogglePerspective);
    on<RecenterPressed>(_onRecenter);
    on<FlyToPoiRequested>(_onFlyToPoi);
    on<ToggleDrawingPressed>(_onToggleDrawingPressed);
    on<SetDrawingEnabled>(_onSetDrawingEnabled);
    on<AreaDrawZoomOkChanged>(_onAreaDrawZoomOkChanged);
    on<SyncBasemapToAppTheme>(_onSyncBasemapToAppTheme);
    on<FitRouteBoundsRequested>(_onFitRouteBounds);
    on<RefreshViewportRequested>(_onRefreshViewport);
  }

  void _onInitialized(MapInitialized event, Emitter<MapState> emit) {
    _controller = event.controller;
    emit(state.copyWith(isMapReady: true));
    // ignore: avoid_print
    print('[MapBloc] MapInitialized -> isMapReady=true');
  }

  void _onCycleBasemap(CycleBasemapPressed event, Emitter<MapState> emit) {
    final next = state.basemap.next();
    emit(state.copyWith(basemap: next));
    // ignore: avoid_print
    print('[MapBloc] CycleBasemapPressed -> basemap=${next.label}');
  }

  void _onTogglePerspective(
    TogglePerspectivePressed event,
    Emitter<MapState> emit,
  ) {
    final next = state.perspective.toggle();
    emit(state.copyWith(perspective: next));
    // ignore: avoid_print
    print('[MapBloc] TogglePerspectivePressed -> perspective=${next.label}');
  }

  void _onRecenter(RecenterPressed event, Emitter<MapState> emit) {
    emit(state.copyWith(recenterTick: state.recenterTick + 1));
    // ignore: avoid_print
    print(
      '[MapBloc] RecenterPressed -> recenterTick=${state.recenterTick + 1}',
    );
  }

  void _onFlyToPoi(FlyToPoiRequested event, Emitter<MapState> emit) {
    emit(
      state.copyWith(
        flyToPoiTick: state.flyToPoiTick + 1,
        flyToPoiLat: event.latitude,
        flyToPoiLng: event.longitude,
        flyToPoiZoom: event.zoom,
      ),
    );
    log(
      '[MapBloc] FlyToPoiRequested lat=${event.latitude} lng=${event.longitude} '
      'zoom=${event.zoom}',
    );
  }

  void _onFitRouteBounds(
    FitRouteBoundsRequested event,
    Emitter<MapState> emit,
  ) {
    emit(
      state.copyWith(
        fitRouteTick: state.fitRouteTick + 1,
        fitRouteMinLat: event.minLat,
        fitRouteMaxLat: event.maxLat,
        fitRouteMinLng: event.minLng,
        fitRouteMaxLng: event.maxLng,
        fitRouteBearing: event.bearing,
      ),
    );
    log(
      '[MapBloc] FitRouteBoundsRequested '
      'lat=[${event.minLat},${event.maxLat}] lng=[${event.minLng},${event.maxLng}] '
      'bearing=${event.bearing}',
    );
  }

  void _onToggleDrawingPressed(
    ToggleDrawingPressed event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(isDrawing: !state.isDrawing));
    log('[MapBloc] ToggleDrawingPressed -> isDrawing=${!state.isDrawing}');
  }

  void _onSetDrawingEnabled(SetDrawingEnabled event, Emitter<MapState> emit) {
    if (state.isDrawing == event.enabled) return;
    emit(state.copyWith(isDrawing: event.enabled));
    log('[MapBloc] SetDrawingEnabled -> isDrawing=${event.enabled}');
  }

  void _onAreaDrawZoomOkChanged(
    AreaDrawZoomOkChanged event,
    Emitter<MapState> emit,
  ) {
    if (state.areaDrawZoomOk == event.ok) return;
    emit(state.copyWith(areaDrawZoomOk: event.ok));
    log('[MapBloc] AreaDrawZoomOkChanged -> areaDrawZoomOk=${event.ok}');
  }

  void _onSyncBasemapToAppTheme(
    SyncBasemapToAppTheme event,
    Emitter<MapState> emit,
  ) {
    final target = event.isDark ? MapBasemap.dark : MapBasemap.streets;
    if (state.basemap == target) return;
    emit(state.copyWith(basemap: target));
    log('[MapBloc] SyncBasemapToAppTheme -> basemap=${target.label}');
  }

  void _onRefreshViewport(RefreshViewportRequested event, Emitter<MapState> emit) {
    emit(state.copyWith(refreshViewportTick: state.refreshViewportTick + 1));
    log('[MapBloc] RefreshViewportRequested -> tick=${state.refreshViewportTick + 1}');
  }

  bool get hasController => _controller != null;
}
