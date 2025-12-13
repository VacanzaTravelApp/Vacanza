import 'package:flutter_bloc/flutter_bloc.dart';

import 'map_event.dart';
import 'map_state.dart';

/// HomeMapScreen için state yönetimi.
///
/// Bu task (156) Mapbox olmadan da çalışmalı:
/// - ToggleViewModePressed -> viewMode değişir
/// - RecenterPressed -> recenterTick artar (UI/print ile doğrulanır)
/// - Controller nullken crash olmamalı
class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc() : super(MapState.initial()) {
    on<MapInitialized>(_onMapInitialized);
    on<ToggleViewModePressed>(_onToggleViewMode);
    on<RecenterPressed>(_onRecenterPressed);
  }

  void _onMapInitialized(MapInitialized event, Emitter<MapState> emit) {
    // Mapbox 137 ile gelince burada gerçek controller setlenecek.
    emit(
      state.copyWith(
        controller: event.controller,
        isMapReady: true,
        clearError: true,
      ),
    );

    // Acceptance Criteria: log/print ile doğrulama
    // ignore: avoid_print
    print('[MapBloc] MapInitialized -> isMapReady=true');
  }

  void _onToggleViewMode(ToggleViewModePressed event, Emitter<MapState> emit) {
    // MapViewMode modelinde `next()` zaten var.
    final nextMode = state.viewMode.next();

    emit(
      state.copyWith(
        viewMode: nextMode,
        clearError: true,
      ),
    );

    // ignore: avoid_print
    print('[MapBloc] ToggleViewModePressed -> viewMode=${nextMode.label}');
  }

  void _onRecenterPressed(RecenterPressed event, Emitter<MapState> emit) {
    // Controller yoksa bile crash istemiyoruz.
    // Şimdilik sadece tick arttırıyoruz. Mapbox gelince bu tick -> kamerayı resetleyecek.
    emit(
      state.copyWith(
        recenterTick: state.recenterTick + 1,
        clearError: true,
      ),
    );

    // ignore: avoid_print
    print('[MapBloc] RecenterPressed -> recenterTick=${state.recenterTick + 1}');
  }
}