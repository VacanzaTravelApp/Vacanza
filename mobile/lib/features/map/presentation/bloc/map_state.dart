import '../../data/models/map_basemap.dart';
import '../../data/models/map_perspective.dart';

/// Map ekranının state'i.
/// Web ile aynı ayrım: [basemap] (streets/dark/satellite) × [perspective] (2D/3D) = 6 kombinasyon.
class MapState {
  final MapBasemap basemap;
  final MapPerspective perspective;
  final bool isMapReady;
  final int recenterTick;
  final int flyToPoiTick;
  final double? flyToPoiLat;
  final double? flyToPoiLng;
  final double flyToPoiZoom;
  final String? lastErrorMessage;
  final bool isDrawing;

  const MapState({
    required this.basemap,
    required this.perspective,
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
        basemap: MapBasemap.streets,
        perspective: MapPerspective.mode2D,
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
    MapBasemap? basemap,
    MapPerspective? perspective,
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
      basemap: basemap ?? this.basemap,
      perspective: perspective ?? this.perspective,
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
