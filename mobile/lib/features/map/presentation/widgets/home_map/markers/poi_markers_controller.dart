import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import '../../../../../poi_search/data/models/poi.dart';

class PoiMarkersController {
  final mb.MapboxMap _map;

  mb.PointAnnotationManager? _pointManager;

  final Map<String, dynamic> _byPoiId = <String, dynamic>{};
  final Map<String, Uint8List> _iconCache = <String, Uint8List>{};

  PoiMarkersController(this._map);

  bool get isReady => _pointManager != null;

  Future<void> init() async {
    if (_pointManager != null) {
      await dispose();
    }

    // ✅ Tip verme: bazı sürümlerde AnnotationPlugin diye bir type yok
    var annotations = _map.annotations;

    // küçük retry loop (style load anında null gelebiliyor)
    int attempt = 0;
    while (annotations == null && attempt < 5) {
      attempt++;
      log('[PoiMarkersController] init: map.annotations is null, retry #$attempt');
      await Future.delayed(const Duration(milliseconds: 200));
      annotations = _map.annotations;
    }

    if (annotations == null) {
      log('[PoiMarkersController] init: map.annotations still null -> abort');
      return;
    }

    _pointManager = await annotations.createPointAnnotationManager();
    log('[PoiMarkersController] init completed');
  }
  Future<void> clear() async {
    final mgr = _pointManager;
    if (mgr == null) {
      log('[PoiMarkersController] clear: manager is null');
      return;
    }

    try {
      _byPoiId.clear();
      await mgr.deleteAll();
      log('[PoiMarkersController] cleared all markers');
    } catch (e) {
      log('[PoiMarkersController] deleteAll failed: $e');
    }
  }

  String _normCategory(String raw) => raw.trim().toLowerCase();

  String _assetPathFor(String key) {
    switch (key) {
      case 'restaurants':
        return 'assets/core/theme/poi/poi_restaurant.png';
      case 'cafe':
        return 'assets/core/theme/poi/poi_cafe.png';
      case 'museum':
        return 'assets/core/theme/poi/poi_museum.png';
      case 'monuments':
        return 'assets/core/theme/poi/poi_monument.png';
      case 'parks':
        return 'assets/core/theme/poi/poi_park.png';
      default:
        return 'assets/core/theme/poi/poi_monument.png';
    }
  }

  Future<Uint8List> _loadMarkerPngForCategory(String category) async {
    final key = _normCategory(category);

    final cached = _iconCache[key];
    if (cached != null) return cached;

    final path = _assetPathFor(key);

    try {
      final ByteData data = await rootBundle.load(path);
      final Uint8List bytes = data.buffer.asUint8List();

      _iconCache[key] = bytes;
      log('[PoiMarkersController] loaded icon "$key" from "$path" (${bytes.length} bytes)');
      return bytes;
    } catch (e) {
      log('[PoiMarkersController] FAILED to load "$key" from "$path": $e');

      // 1x1 transparent PNG fallback
      final fallback = Uint8List.fromList(<int>[
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82
      ]);

      _iconCache[key] = fallback;
      return fallback;
    }
  }

  Future<void> setPois(List<Poi> pois) async {
    final mgr = _pointManager;
    if (mgr == null) return;

    await clear();
    if (pois.isEmpty) return;

    // ✅ önce unique kategorileri yükle
    final categories = <String>{};
    for (final p in pois) {
      categories.add(_normCategory(p.category));
    }
    for (final c in categories) {
      await _loadMarkerPngForCategory(c);
    }

    final options = <mb.PointAnnotationOptions>[];
    final createdPoiIds = <String>[];

    for (final poi in pois) {
      if (poi.latitude == 0.0 && poi.longitude == 0.0) continue;

      final key = _normCategory(poi.category);
      final png = _iconCache[key]!; // ✅ artık kesin var

      options.add(
        mb.PointAnnotationOptions(
          geometry: mb.Point(coordinates: mb.Position(poi.longitude, poi.latitude)),
          image: png,
          iconSize: 1.4,
        ),
      );

      createdPoiIds.add(poi.poiId);
    }

    if (options.isEmpty) return;

    final created = await mgr.createMulti(options);
    for (int i = 0; i < created.length && i < createdPoiIds.length; i++) {
      _byPoiId[createdPoiIds[i]] = created[i];
    }
  }

  Future<void> dispose() async {
    log('[PoiMarkersController] disposing...');
    await clear();
    _pointManager = null;
    // _iconCache.clear(); // istersen tut (performans)
  }
}