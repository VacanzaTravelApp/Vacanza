import 'package:flutter_bloc/flutter_bloc.dart';

import 'map_event.dart';
import 'map_state.dart';

/// HomeMapScreen için MapBloc.
///
/// Bu taskta Mapbox şart değil.
/// - Controller setlenince MapInitialized(controller) gelir.
/// - Toggle/Recenter eventleri state'i günceller.
/// 137'de:
/// - controller tipini Mapbox controller'a çevirip
/// - viewMode + recenter davranışını gerçek kameraya uygularız.
class MapBloc extends Bloc<MapEvent, MapState> {
  /// Map controller referansı.
  /// Şimdilik Object? (Mapbox yok), 137'de gerçek tipe çekilecek.
  Object? _controller;

  MapBloc() : super(MapState.initial()) {
    on<MapInitialized>(_onInitialized);
    on<MapToggleViewModePressed>(_onToggleViewMode);
    on<MapRecenterPressed>(_onRecenter);
  }

  void _onInitialized(MapInitialized event, Emitter<MapState> emit) {
    _controller = event.controller;

    // Controller null geldiyse crash yok, sadece mapReady false kalır.
    final ready = _controller != null;

    emit(
      state.copyWith(
        isMapReady: ready,
        lastErrorMessage: ready ? null : 'Map controller is null (placeholder mode).',
      ),
    );

    // Acceptance Criteria için doğrulama (istersen kaldırırsın)
    // ignore: avoid_print
    print('[MapBloc] initialized -> isMapReady=$ready');
  }

  void _onToggleViewMode(
      MapToggleViewModePressed event,
      Emitter<MapState> emit,
      ) {
    final nextMode =
    state.viewMode == MapViewMode.twoD ? MapViewMode.threeD : MapViewMode.twoD;

    emit(state.copyWith(viewMode: nextMode));

    // ignore: avoid_print
    print('[MapBloc] viewMode -> $nextMode');

    // 137'de burada controller'a pitch/bearing uygulanacak.
    // Örn: if (_controller != null) { controller.animateCamera(...) }
  }

  void _onRecenter(MapRecenterPressed event, Emitter<MapState> emit) {
    // Controller yoksa safe davran: crash yok.
    if (_controller == null) {
      emit(state.copyWith(lastErrorMessage: 'Recenter ignored: controller not ready.'));
      // ignore: avoid_print
      print('[MapBloc] recenter ignored (controller null)');
      return;
    }

    emit(state.copyWith(recenterTick: state.recenterTick + 1, lastErrorMessage: null));

    // ignore: avoid_print
    print('[MapBloc] recenterTick -> ${state.recenterTick + 1}');

    // 137'de burada gerçek camera reset çağrısı yapılacak.
  }
}