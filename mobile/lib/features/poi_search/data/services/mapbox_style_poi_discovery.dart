import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import '../models/poi.dart';
import '../models/poi_category_catalog.dart';
import '../models/poi_data_source.dart';

/// Web [MapPage.jsx] `handleMapIdle` ile aynı tercih edilen katman kimlikleri.
/// Standard style’da id’ler import önekli olabilir; [resolveQueryableLayerIds] ile filtrelenir.
const List<String> kPreferredStylePoiLayerSubstrings = <String>[
  'poi-label',
  'poi_label',
  'settlement-label',
  'settlement_label',
  'medical-label',
  'medical_label',
  'transit-label',
  'transit_label',
  'airport-label',
  'airport_label',
  'natural-label',
  'natural_label',
  'park-label',
  'park_label',
  'place-label',
  'place_label',
  'point-of-interest',
  'point_of_interest',
];

/// Mapbox harita vektör katmanlarından görünür POI okuma ([queryRenderedFeatures]).
class MapboxStylePoiDiscovery {
  MapboxStylePoiDiscovery._();

  static const double minZoomInclusive = 12.0;

  /// queryRenderedFeatures çok sonuç döndürebilir; işlem süresini sınırla.
  static const int _maxRawFeatures = 2500;

  /// Stilde var olan ve tercih listesiyle eşleşen katman id’leri.
  static Future<List<String>> resolveQueryableLayerIds(mb.MapboxMap map) async {
    try {
      final layers = await map.style.getStyleLayers();
      final ids = layers
          .map((e) => e?.id)
          .whereType<String>()
          .toList(growable: false);

      final out = <String>[];
      for (final id in ids) {
        for (final sub in kPreferredStylePoiLayerSubstrings) {
          if (id == sub || id.contains(sub)) {
            out.add(id);
            break;
          }
        }
      }
      return out.toSet().toList()..sort();
    } catch (e, st) {
      log('[MapboxStylePoiDiscovery] getStyleLayers failed: $e\n$st');
      return const [];
    }
  }

  /// Web `handleMapIdle` özellik → POI dönüşümü.
  static Future<List<Poi>> discoverVisiblePois({
    required mb.MapboxMap map,
    required Size logicalViewportSize,
  }) async {
    if (logicalViewportSize.width < 16 || logicalViewportSize.height < 16) {
      return const [];
    }

    final double zoom;
    try {
      final cs = await map.getCameraState();
      zoom = cs.zoom;
      if (zoom < minZoomInclusive) {
        return const [];
      }
    } catch (e) {
      log('[MapboxStylePoiDiscovery] getCameraState failed: $e');
      return const [];
    }

    final layerIds = await resolveQueryableLayerIds(map);
    // Standard stilde katman id’leri farklı önekli olabiliyor; eşleşme yoksa
    // layerIds=null ile tüm uygun katmanlarda sorgula (iOS: nil layerIds).
    final mb.RenderedQueryOptions options = layerIds.isEmpty
        ? mb.RenderedQueryOptions()
        : mb.RenderedQueryOptions(layerIds: layerIds);

    if (layerIds.isEmpty) {
      log(
        '[MapboxStylePoiDiscovery] no substring-matched POI layers — '
        'querying all rendered features in viewport (zoom=$zoom)',
      );
    } else {
      log(
        '[MapboxStylePoiDiscovery] querying ${layerIds.length} layer(s), '
        'zoom=$zoom',
      );
    }

    final box = mb.ScreenBox(
      min: mb.ScreenCoordinate(x: 0, y: 0),
      max: mb.ScreenCoordinate(
        x: logicalViewportSize.width,
        y: logicalViewportSize.height,
      ),
    );

    final geometry = mb.RenderedQueryGeometry.fromScreenBox(box);

    List<mb.QueriedRenderedFeature?> raw;
    try {
      raw = await map.queryRenderedFeatures(geometry, options);
    } catch (e, st) {
      log('[MapboxStylePoiDiscovery] queryRenderedFeatures failed: $e\n$st');
      return const [];
    }

    final slice = raw.length > _maxRawFeatures
        ? raw.sublist(0, _maxRawFeatures)
        : raw;

    final out = <Poi>[];
    final seenCoords = <String>{};

    for (final wrapped in slice) {
      if (wrapped == null) continue;
      final qf = wrapped.queriedFeature;
      final poi = _poiFromQueriedFeature(qf);
      if (poi == null) continue;

      final key =
          '${poi.latitude.toStringAsFixed(4)},${poi.longitude.toStringAsFixed(4)}';
      if (seenCoords.add(key)) {
        out.add(poi);
      }
    }

    log('[MapboxStylePoiDiscovery] parsed ${out.length} POIs from ${slice.length} raw hits');
    return out;
  }

  static Poi? _poiFromQueriedFeature(mb.QueriedFeature qf) {
    final root = _asStringKeyMap(qf.feature);
    if (root == null) return null;

    final geom = _asStringKeyMap(root['geometry']);
    final coords = _pointLngLat(geom);
    if (coords == null) return null;

    final props = _asStringKeyMap(root['properties']) ?? root;

    final name = _firstNonEmptyName(props);
    if (name == null) return null;

    // Master mapping: önce Mapbox canonical / type, sonra ikon (maki), sınıf.
    // (Ürün spesifikasyonu: canonical_id veya type → UI kategorisi.)
    final styleToken = _collapseDottedCategoryToken(
      _styleCategoryToken(props) ?? 'poi',
    );
    var rawCategory = PoiCategoryCatalog.normalizeCategory(styleToken);
    if (rawCategory.isEmpty) rawCategory = 'poi';

    final lng = coords[0];
    final lat = coords[1];

    final safeName = PoiCategoryCatalog.safePoiTitle(
      name: name,
      rawCategory: rawCategory,
    );

    final id =
        'mb-$name-${lng.toStringAsFixed(5)}-${lat.toStringAsFixed(5)}';

    return Poi(
      poiId: id,
      name: safeName,
      category: rawCategory,
      latitude: lat,
      longitude: lng,
      source: PoiDataSource.mapboxStyle,
    );
  }

  static Map<String, Object?>? _asStringKeyMap(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  static String? _stringProp(Map<String, Object?>? m, String key) {
    if (m == null) return null;
    final v = m[key];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// [MapPage.jsx] `type || maki || class || …` + Standard stil `canonical_id` vb.
  static String? _styleCategoryToken(Map<String, Object?> props) {
    const keys = <String>[
      'mapbox_canonical_id',
      'canonical_id',
      'canonicalId',
      'type',
      'maki',
      'class',
      'subclass',
      'category',
      'category_en',
      'group',
    ];
    for (final k in keys) {
      final s = _stringProp(props, k);
      if (s != null) return s;
    }
    return null;
  }

  /// `tourism.attraction.museum` → `museum`; `food_and_drink.cafe` → `cafe` (alias eşlemesi için).
  static String _collapseDottedCategoryToken(String token) {
    final t = token.trim();
    if (!t.contains('.')) return t;
    final parts = t.split('.');
    for (var i = parts.length - 1; i >= 0; i--) {
      final s = parts[i].trim();
      if (s.isNotEmpty) return s;
    }
    return t;
  }

  static String? _firstNonEmptyName(Map<String, Object?> props) {
    const keys = <String>[
      'name_en',
      'name',
      'name_latin',
      'name_de',
      'name_int',
      'text_field',
    ];
    for (final k in keys) {
      final s = _stringProp(props, k);
      if (s != null) return s;
    }
    return null;
  }

  static List<double>? _pointLngLat(Map<String, Object?>? geom) {
    if (geom == null) return null;
    final t = geom['type']?.toString().toLowerCase();
    final c = geom['coordinates'];
    if (c is! List) return null;

    if (t == 'point' && c.length >= 2) {
      return <double>[(c[0] as num).toDouble(), (c[1] as num).toDouble()];
    }
    if (t == 'multipoint' && c.isNotEmpty && c[0] is List) {
      final p = c[0] as List;
      if (p.length >= 2) {
        return <double>[(p[0] as num).toDouble(), (p[1] as num).toDouble()];
      }
    }
    if (t == 'linestring' && c.isNotEmpty && c[0] is List) {
      final p = c[0] as List;
      if (p.length >= 2) {
        return <double>[(p[0] as num).toDouble(), (p[1] as num).toDouble()];
      }
    }
    return null;
  }
}
