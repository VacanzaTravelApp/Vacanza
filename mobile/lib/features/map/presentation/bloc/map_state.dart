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
  final int fitRouteTick;
  final double? fitRouteMinLat;
  final double? fitRouteMaxLat;
  final double? fitRouteMinLng;
  final double? fitRouteMaxLng;
  final double? fitRouteBearing;
  final String? lastErrorMessage;
  final bool isDrawing;
  final int refreshViewportTick;

  const MapState({
    required this.basemap,
    required this.perspective,
    required this.isMapReady,
    required this.recenterTick,
    required this.flyToPoiTick,
    this.flyToPoiLat,
    this.flyToPoiLng,
    this.flyToPoiZoom = 16.0,
    required this.fitRouteTick,
    this.fitRouteMinLat,
    this.fitRouteMaxLat,
    this.fitRouteMinLng,
    this.fitRouteMaxLng,
    this.fitRouteBearing,
    required this.isDrawing,
    this.lastErrorMessage,
    this.refreshViewportTick = 0,
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
    fitRouteTick: 0,
    fitRouteMinLat: null,
    fitRouteMaxLat: null,
    fitRouteMinLng: null,
    fitRouteMaxLng: null,
    fitRouteBearing: null,
    lastErrorMessage: null,
    isDrawing: false,
    refreshViewportTick: 0,
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
    int? fitRouteTick,
    double? fitRouteMinLat,
    double? fitRouteMaxLat,
    double? fitRouteMinLng,
    double? fitRouteMaxLng,
    double? fitRouteBearing,
    String? lastErrorMessage,
    bool? isDrawing,
    int? refreshViewportTick,
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
      fitRouteTick: fitRouteTick ?? this.fitRouteTick,
      fitRouteMinLat: fitRouteMinLat ?? this.fitRouteMinLat,
      fitRouteMaxLat: fitRouteMaxLat ?? this.fitRouteMaxLat,
      fitRouteMinLng: fitRouteMinLng ?? this.fitRouteMinLng,
      fitRouteMaxLng: fitRouteMaxLng ?? this.fitRouteMaxLng,
      fitRouteBearing: fitRouteBearing ?? this.fitRouteBearing,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
      isDrawing: isDrawing ?? this.isDrawing,
      refreshViewportTick: refreshViewportTick ?? this.refreshViewportTick,
    );
  }
}
