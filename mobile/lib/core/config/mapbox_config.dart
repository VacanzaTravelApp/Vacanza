import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Mapbox ile ilgili tüm config değerleri burada tutulur.
///
/// ⚠️ ŞİMDİLİK:
/// - Access token hardcoded.
/// - Prod ortamda .env veya platform config'e taşınabilir.
class MapboxConfig {
  /// Mapbox public access token
  ///
  ///
    static const String styleStreets = 'mapbox://styles/mapbox/streets-v12';
     static const String styleSatellite = 'mapbox://styles/mapbox/satellite-streets-v12';
  /// NOT:
  /// - Bu token PUBLIC token'dır.
  /// - Mobil uygulama içinde bulunması normaldir.
  /// - Secret token ile karıştırma.
  static const String accessToken =
      'pk.eyJ1IjoicHJpeGltYSIsImEiOiJjbTlkMDdhdHcwbW92Mmtxd2swbXMyNTd0In0.c4zFX1Yh1mP4ioGHYiJrfQ';


  static final CameraOptions initialCamera = CameraOptions(
    center: Point(coordinates: Position(29.0, 41.0)),
    zoom: 12,
    pitch: 0, // 2D başlangıç
    bearing: 0,
  );

  /// 2D kamera (straight-down).
  static final CameraOptions camera2D = CameraOptions(
    center: initialCamera.center,
    zoom: initialCamera.zoom,
    pitch: 0,
    bearing: 0,
  );

  /// 3D kamera (tilt applied).
  static final CameraOptions camera3D = CameraOptions(
    center: initialCamera.center,
    zoom: initialCamera.zoom,
    pitch: 55, // 3D hissi için tilt
    bearing: 0,
  );
}