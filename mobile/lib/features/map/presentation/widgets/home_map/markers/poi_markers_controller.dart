import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import '../../../../../poi_search/data/models/poi.dart';
import 'poi_marker_icon_factory.dart';

class PoiMarkersController {
  final mb.MapboxMap _map;

  mb.PointAnnotationManager? _pointManager;

  final Map<String, dynamic> _byPoiId = <String, dynamic>{};
  final Map<String, Uint8List> _iconCache = <String, Uint8List>{};

  final PoiMarkerIconFactory _factory = const PoiMarkerIconFactory();

  PoiMarkersController(this._map);

  Future<void> init() async {
    _pointManager ??= await _map.annotations.createPointAnnotationManager();
    log('[PoiMarkersController] init -> PointAnnotationManager READY');
  }

  Future<void> clear() async {
    final mgr = _pointManager;
    if (mgr == null) return;

    try {
      await mgr.deleteAll();
    } catch (e) {
      log('[PoiMarkersController] deleteAll failed: $e');
    }

    _byPoiId.clear();
  }

  String _norm(String s) => s.trim().toLowerCase();

  IconData _iconFor(String key) {
    switch (key) {
      case 'restaurants':
        return Icons.restaurant_rounded;
      case 'cafe':
        return Icons.local_cafe_rounded;
      case 'museum':
        return Icons.museum_rounded;
      case 'monuments':
        return Icons.account_balance_rounded;
      case 'parks':
        return Icons.park_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  Color _colorFor(String key) {
    switch (key) {
      case 'museum':
        return const Color(0xFF0096FF);
      case 'restaurants':
        return const Color(0xFFFFD166);
      case 'cafe':
        return const Color(0xFFB37AFF);
      case 'monuments':
        return const Color(0xFFFF9F43);
      case 'parks':
        return const Color(0xFF2ECC71);
      default:
        return const Color(0xFF0096FF);
    }
  }

  Future<Uint8List> _markerPngForCategory(String category) async {
    final key = _norm(category);

    final cached = _iconCache[key];
    if (cached != null) return cached;

    final png = await _factory.buildPng(
      icon: _iconFor(key),
      bgColor: _colorFor(key),
      sizePx: 100,
      iconScale: 0.58,
      iconColor: Colors.white,

      // İnce glow
      enableGlow: true,
      glowSigma: 10,
      glowOpacity: 0.22,
      padRatio: 0.18,
    );

    _iconCache[key] = png;
    return png;
  }

  Future<void> setPois(List<Poi> pois) async {
    final mgr = _pointManager;
    if (mgr == null) return;

    // Hot reload sonrası “aynı görünüyor” hissi için cache’i temizlemek iyi
    PoiMarkerIconFactory.clearCache();
    _iconCache.clear();

    await clear();

    final options = <mb.PointAnnotationOptions>[];

    for (final poi in pois) {
      if (poi.latitude == 0.0 && poi.longitude == 0.0) continue;

      final png = await _markerPngForCategory(poi.category);

      options.add(
        mb.PointAnnotationOptions(
          geometry: mb.Point(
            coordinates: mb.Position(poi.longitude, poi.latitude),
          ),
          image: png,
          iconSize: 1.35,
        ),
      );
    }

    if (options.isEmpty) return;

    final created = await mgr.createMulti(options);

    int idx = 0;
    for (final poi in pois) {
      if (poi.latitude == 0.0 && poi.longitude == 0.0) continue;
      _byPoiId[poi.poiId] = created[idx];
      idx++;
    }

    log('[PoiMarkersController] setPois -> markers=${created.length}');
  }

  Future<void> dispose() async {
    await clear();
    _pointManager = null;
  }
}