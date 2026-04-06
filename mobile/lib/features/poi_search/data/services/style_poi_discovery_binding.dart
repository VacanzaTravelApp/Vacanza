import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

/// [MapCanvasMapbox] haritayı ve görünür alan boyutunu buraya bağlar;
/// [CompositePoiSearchRepository] keşif sırasında okur.
class StylePoiDiscoveryBinding {
  mb.MapboxMap? _map;
  Size _viewportSize = const Size(400, 800);

  void attachMap(mb.MapboxMap map) {
    _map = map;
  }

  void detachMap() {
    _map = null;
  }

  void updateViewportSize(Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    _viewportSize = size;
  }

  mb.MapboxMap? get map => _map;

  Size get viewportSize => _viewportSize;
}
