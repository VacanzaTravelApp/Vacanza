import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxConfig {
  static const String accessToken =
      'pk.eyJ1IjoicHJpeGltYSIsImEiOiJjbTlkMDdhdHcwbW92Mmtxd2swbXMyNTd0In0.c4zFX1Yh1mP4ioGHYiJrfQ';

  /// ✅ Standard style (3D objects config destekliyor)
  static const String styleStandard = MapboxStyles.STANDARD;

  /// ✅ Satellite görünüm (Standard Satellite)
  static const String styleStandardSatellite = MapboxStyles.STANDARD_SATELLITE;

  /// Başlangıç kamera
  static final CameraOptions initialCamera = CameraOptions(
    center: Point(coordinates: Position(29.0, 41.0)),
    zoom: 13.5,
    pitch: 0,
    bearing: 0,
  );

  static final CameraOptions camera2D = CameraOptions(
    center: initialCamera.center,
    zoom: 13.5,
    pitch: 0,
    bearing: 0,
  );

  /// ✅ 3D binalar için genelde zoom’u biraz yükseltmek gerekiyor
  static final CameraOptions camera3D = CameraOptions(
    center: initialCamera.center,
    zoom: 16.0,
    pitch: 60,
    bearing: 0,
  );
}