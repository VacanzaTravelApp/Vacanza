import '../../data/models/map_view_mode.dart';

/// Map ekranının state'i.
/// Mapbox controller hazır olduğunda isMapReady true olur.
/// recenterTick: her recenter basışında artar (listener tetiklemek için).
/// flyToPoiTick: POI detaydan "Haritada göster" ile kamera hedefi (listener).
class MapState {
  final MapViewMode viewMode;
  final bool isMapReady;
  final int recenterTick;
  /// Her artışta [MapCanvasMapbox] ilgili POI'de kamerayı uçurur.
  final int flyToPoiTick;
  final double? flyToPoiLat;
  final double? flyToPoiLng;
  final double flyToPoiZoom;
  final String? lastErrorMessage;
  final bool isDrawing;
  const MapState({
    required this.viewMode,
    required this.isMapReady,
    required this.recenterTick,
    required this.flyToPoiTick,
    this.flyToPoiLat,
    this.flyToPoiLng,
    this.flyToPoiZoom = 16.0,
    required this.isDrawing,
    this.lastErrorMessage,
  });

  factory MapState.initial() => const MapState(
    viewMode: MapViewMode.mode2D,
    isMapReady: false,
    recenterTick: 0,
    flyToPoiTick: 0,
    flyToPoiLat: null,
    flyToPoiLng: null,
    flyToPoiZoom: 16.0,
    lastErrorMessage: null,
    isDrawing: false,
  );

  MapState copyWith({
    MapViewMode? viewMode,
    bool? isMapReady,
    int? recenterTick,
    int? flyToPoiTick,
    double? flyToPoiLat,
    double? flyToPoiLng,
    double? flyToPoiZoom,
    String? lastErrorMessage,
    bool? isDrawing,
  }) {
    return MapState(
      viewMode: viewMode ?? this.viewMode,
      isMapReady: isMapReady ?? this.isMapReady,
      recenterTick: recenterTick ?? this.recenterTick,
      flyToPoiTick: flyToPoiTick ?? this.flyToPoiTick,
      flyToPoiLat: flyToPoiLat ?? this.flyToPoiLat,
      flyToPoiLng: flyToPoiLng ?? this.flyToPoiLng,
      flyToPoiZoom: flyToPoiZoom ?? this.flyToPoiZoom,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
      isDrawing: isDrawing ?? this.isDrawing,
    );
  }
}