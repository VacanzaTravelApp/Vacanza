/// POI / harita davranışı (web `VITE_*` ile hizalı).
class PoiMapConfig {
  PoiMapConfig._();

  /// `flutter run --dart-define=USE_MAPBOX_AREA_POI_SEARCH=false` ile kapatılabilir.
  static const bool useMapboxAreaSearch = bool.fromEnvironment(
    'USE_MAPBOX_AREA_POI_SEARCH',
    defaultValue: true,
  );

  /// Alan çizimi: web `MIN_ZOOM_FOR_AREA_DRAW` ile aynı.
  static const double minZoomForAreaDraw = 11.0;

  /// Alan çizimi: web `MAX_ZOOM_FOR_AREA_DRAW` ile aynı.
  /// Bu zoom seviyesinden yakın çizim yapılamaz (alan çok küçük kalır).
  static const double maxZoomForAreaDraw = 18.0;
}
