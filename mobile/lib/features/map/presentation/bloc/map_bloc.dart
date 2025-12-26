import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../data/models/map_view_mode.dart';
import 'map_event.dart';
import 'map_state.dart';

/// HomeMapScreen'deki UI state yönetimini tek yerde tutar.
/// MapboxMap controller BLoC'a sadece "hazır" bilgisi için gelir.
/// Kamera değişimi gibi side-effect işleri widget tarafında BlocListener ile yapılır
/// (çünkü bloc içinde mapbox çağrıları yaparsan test/maintain zorlaşır).
class MapBloc extends Bloc<MapEvent, MapState> {
  MapboxMap? _controller;

  MapBloc() : super(MapState.initial()) {
    on<MapInitialized>(_onInitialized);
    on<ToggleViewModePressed>(_onToggleMode);
    on<RecenterPressed>(_onRecenter);
    on<ToggleDrawingPressed>(_onToggleDrawingPressed);
    on<SetDrawingEnabled>(_onSetDrawingEnabled);
  }

  void _onInitialized(MapInitialized event, Emitter<MapState> emit) {
    _controller = event.controller;
    emit(state.copyWith(isMapReady: true));

    // Debug amaçlı (AC: state değişimi log/print ile doğrulanabilir)
    // ignore: avoid_print
    print('[MapBloc] MapInitialized -> isMapReady=true');
  }

  void _onToggleMode(ToggleViewModePressed event, Emitter<MapState> emit) {
    final next = state.viewMode.next();

    emit(state.copyWith(viewMode: next));

    // ignore: avoid_print
    print('[MapBloc] ToggleViewModePressed -> viewMode=${next.label}');
  }

  void _onRecenter(RecenterPressed event, Emitter<MapState> emit) {
    // Controller yoksa crash yok: sadece state tick artırıp listener’a sinyal veriyoruz.
    emit(state.copyWith(recenterTick: state.recenterTick + 1));

    // ignore: avoid_print
    print('[MapBloc] RecenterPressed -> recenterTick=${state.recenterTick + 1}');
  }
  void _onToggleDrawingPressed(
      ToggleDrawingPressed event,
      Emitter<MapState> emit,
      ) {
    emit(state.copyWith(isDrawing: !state.isDrawing));

      log('[MapBloc] ToggleDrawingPressed -> isDrawing=${!state.isDrawing}');

  }

  void _onSetDrawingEnabled(
      SetDrawingEnabled event,
      Emitter<MapState> emit,
      ) {
    if (state.isDrawing == event.enabled) return;
    emit(state.copyWith(isDrawing: event.enabled));

      log('[MapBloc] SetDrawingEnabled -> isDrawing=${event.enabled}');
  }
  /// İstersen ileride UI'da "controller var mı" kontrolü için okunabilir.
  bool get hasController => _controller != null;
}