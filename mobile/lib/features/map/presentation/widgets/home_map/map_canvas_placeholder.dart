import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapCanvasMapbox extends StatelessWidget {
  const MapCanvasMapbox({super.key});

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: const ValueKey('mapbox-map'),

      // ÖNEMLİ: Default "standard" yerine streets deniyoruz
      styleUri: MapboxStyles.MAPBOX_STREETS,

      cameraOptions: CameraOptions(
        center: Point(coordinates: Position(29.0, 41.0)),
        zoom: 12,
        pitch: 0,
      ),
    );
  }
}