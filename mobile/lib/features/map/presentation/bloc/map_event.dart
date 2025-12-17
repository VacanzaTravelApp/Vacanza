import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Map ekranından gelen event'ler.
abstract class MapEvent {
  const MapEvent();
}

/// MapWidget controller hazır olunca tetiklenir.
class MapInitialized extends MapEvent {
  final MapboxMap controller;
  const MapInitialized(this.controller);
}

class ToggleViewModePressed extends MapEvent {
  const ToggleViewModePressed();
}

class RecenterPressed extends MapEvent {
  const RecenterPressed();
}