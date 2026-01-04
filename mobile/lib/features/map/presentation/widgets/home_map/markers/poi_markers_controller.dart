// poi_markers_controller.dart
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import '../../../../../poi_search/data/models/poi.dart';
import 'poi_marker_icon_factory.dart';

/// POI listesini Mapbox marker'a çeviren controller.
/// - Marker görseli: Flutter Icons.* runtime PNG'ye çevrilir (asset yok).
/// - Yeni search gelince eski marker'lar temizlenir.
/// - Marker id = poiId şartını app tarafında map ile tutar (poiId -> annotation).
///
/// Önemli not:
/// - loadStyleURI/viewMode değişimi sonrası annotation manager geçersiz olabiliyor.
///   Bu yüzden reinitAfterStyleChange() çağrılmalı.
class PoiMarkersController {
  final mb.MapboxMap _map;

  mb.PointAnnotationManager? _pointManager;

  /// poiId -> annotation
  final Map<String, dynamic> _byPoiId = <String, dynamic>{};

  /// categoryKey -> png bytes cache
  final Map<String, Uint8List> _iconCache = <String, Uint8List>{};

  final PoiMarkerIconFactory _factory = const PoiMarkerIconFactory();

  PoiMarkersController(this._map);

  Future<void> init() async {
    _pointManager ??= await _map.annotations.createPointAnnotationManager();
  }

  /// Style değişince Mapbox annotation manager resetlenebiliyor.
  /// Bu metot, manager'ı yeniden kurar ve local mapping state'i temizler.
  Future<void> reinitAfterStyleChange() async {
    _pointManager = await _map.annotations.createPointAnnotationManager();
    _byPoiId.clear();
    // icon cache'i tutmak istersen silme. PNG üretimi pahalı olabilir.
    // _iconCache.clear();
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

  String _normCategory(String raw) => raw.trim().toLowerCase();

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
    final key = _normCategory(category);

    final cached = _iconCache[key];
    if (cached != null) return cached;

    final png = await _factory.buildPng(
      icon: _iconFor(key),
      bgColor: _colorFor(key),
      sizePx: 112,
      iconSizePx: 64,
      iconColor: Colors.white,
      glowEnabled: true,
      glowBlurSigma: 10,
      glowOpacity: 0.22,
    );

    _iconCache[key] = png;
    return png;
  }

  Future<void> setPois(List<Poi> pois) async {
    final mgr = _pointManager;
    if (mgr == null) return;

    // Yeni sonuç gelince eskileri temizle
    await clear();

    if (pois.isEmpty) return;

    final options = <mb.PointAnnotationOptions>[];
    final createdPoiIds = <String>[];

    for (final poi in pois) {
      // Invalid koordinatları çizme
      if (poi.latitude == 0.0 && poi.longitude == 0.0) continue;

      final png = await _markerPngForCategory(poi.category);

      options.add(
        mb.PointAnnotationOptions(
          geometry: mb.Point(
            coordinates: mb.Position(poi.longitude, poi.latitude),
          ),
          image: png,

          // ✅ Collision yüzünden bazı markerlar zoom’da çıkıyor gibi görünüyordu.
          // iconSize küçültünce aynı zoom seviyesinde daha çok marker görünür.
          iconSize: 0.9,
        ),
      );
      createdPoiIds.add(poi.poiId);
    }

    if (options.isEmpty) return;

    final created = await mgr.createMulti(options);

    // created listesi options ile aynı sırada döner.
    for (int i = 0; i < created.length; i++) {
      _byPoiId[createdPoiIds[i]] = created[i];
    }
  }

  /// ✅ Widget dispose içinde çağırabilmek için ekledik.
  /// (async ama çağıran tarafta unawaited kullanacağız)
  Future<void> dispose() async {
    await clear();
    _pointManager = null;
  }
}