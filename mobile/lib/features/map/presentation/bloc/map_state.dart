import '../../data/models/map_view_mode.dart';

/// Map ekranının state'i.
/// Mapbox controller hazır olduğunda isMapReady true olur.
/// recenterTick: her recenter basışında artar (listener tetiklemek için).
class MapState {
  final MapViewMode viewMode;
  final bool isMapReady;
  final int recenterTick;
  final String? lastErrorMessage;
  final bool isDrawing;
  const MapState({
    required this.viewMode,
    required this.isMapReady,
    required this.recenterTick,
    required this.isDrawing,
    this.lastErrorMessage,
  });

  factory MapState.initial() => const MapState(
    viewMode: MapViewMode.mode2D,
    isMapReady: false,
    recenterTick: 0,
    lastErrorMessage: null,
    isDrawing: false,
  );

  MapState copyWith({
    MapViewMode? viewMode,
    bool? isMapReady,
    int? recenterTick,
    String? lastErrorMessage,
    bool? isDrawing,
  }) {
    return MapState(
      viewMode: viewMode ?? this.viewMode,
      isMapReady: isMapReady ?? this.isMapReady,
      recenterTick: recenterTick ?? this.recenterTick,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
      isDrawing: isDrawing ?? this.isDrawing,
    );
  }
}