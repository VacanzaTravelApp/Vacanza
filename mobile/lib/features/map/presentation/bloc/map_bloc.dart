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
  }

  void _onInitialized(MapInitialized event, Emitter<MapState> emit) {
    _controller = event.controller;
    emit(state.copyWith(isMapReady: true));

    // Debug amaçlı (AC: state değişimi log/print ile doğrulanabilir)
    // ignore: avoid_print
    print('[MapBloc] MapInitialized -> isMapReady=true');
  }

  void _onToggleMode(ToggleViewModePressed event, Emitter<MapState> emit) {
    // Sat/diğer modları şimdilik kullanmıyoruz: 2D <-> 3D
    final next = (state.viewMode == MapViewMode.mode2D)
        ? MapViewMode.mode3D
        : MapViewMode.mode2D;

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

  /// İstersen ileride UI'da "controller var mı" kontrolü için okunabilir.
  bool get hasController => _controller != null;
}