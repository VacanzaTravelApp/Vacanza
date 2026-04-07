import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'mapbox_access_token.dart';

/// Harita stilleri, kamera ve Mapbox token referansı.
/// Token değeri [mapbox_access_token.dart] içinde tutulur.
class MapboxConfig {
  static String get accessToken => kMapboxAccessToken;

  /// Streets v12 — web MapPage ile aynı stil; POI label katmanları mevcut.
  static const String styleStandard =
      'mapbox://styles/mapbox/streets-v12';

  /// Dark v11 — web gece modu (MapPage STYLES[1]).
  static const String styleDark = 'mapbox://styles/mapbox/dark-v11';

  /// Satellite + streets labels (web ile aynı).
  static const String styleStandardSatellite =
      'mapbox://styles/mapbox/satellite-streets-v12';

  /// Başlangıç kamera
  /// İlk açılış (GPS gelene kadar); stil / 2D-3D geçişinde konum korunur.
  static final CameraOptions initialCamera = CameraOptions(
    center: Point(coordinates: Position(32.8597, 39.9334)),
    zoom: 13.5,
    pitch: 0,
    bearing: 0,
  );

  /// 3D modda hedef eğim (derece).
  static const double pitch3D = 60;

  /// 3D’de binalar için minimum zoom (mevcut zoom daha büyükse dokunulmaz).
  static const double zoomMin3D = 15.0;
}
