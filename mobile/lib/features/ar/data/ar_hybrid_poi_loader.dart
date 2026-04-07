import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import 'package:mobile/features/poi_search/data/models/poi.dart';
import 'package:mobile/features/poi_search/data/models/poi_data_source.dart';
import 'package:mobile/features/poi_search/data/models/selected_area.dart';
import 'package:mobile/features/poi_search/data/services/mapbox_style_poi_discovery.dart';
import 'package:mobile/features/poi_search/data/utils/hybrid_poi_merge.dart';

import 'ar_nearby_poi_dto.dart';
import 'poi_to_ar_poi.dart';
import '../domain/models/ar_poi.dart';

/// `/pois/nearby` + Mapbox stil keşfi (harita [CompositePoiSearchRepository] ile aynı birleştirme).
class ArHybridPoiLoader {
  ArHybridPoiLoader._();

  static const Size kDiscoveryViewport = Size(400, 800);

  static BboxArea bboxAroundPoint({
    required double lat,
    required double lng,
    required double radiusMeters,
  }) {
    const metersPerDegLat = 111000.0;
    final metersPerDegLng = metersPerDegLat * (math.cos(lat * math.pi / 180.0));

    final dLat = radiusMeters / metersPerDegLat;
    final dLng = radiusMeters / metersPerDegLng;

    return BboxArea(
      minLat: lat - dLat,
      minLng: lng - dLng,
      maxLat: lat + dLat,
      maxLng: lng + dLng,
    );
  }

  static Poi? _poiFromNearbyDto(ArNearbyPoiDto dto) {
    final id = dto.poiId.trim();
    if (id.isEmpty) return null;
    return Poi(
      poiId: id,
      name: dto.name,
      category: dto.category,
      latitude: dto.latitude,
      longitude: dto.longitude,
      source: PoiDataSource.backend,
    );
  }

  /// [mapProbe] yoksa yalnızca backend listesi.
  static Future<List<ArPoi>> mergeNearbyAndStylePois({
    required double lat,
    required double lng,
    required double radiusMeters,
    required List<ArNearbyPoiDto> nearbyDtos,
    mb.MapboxMap? mapProbe,
  }) async {
    final bbox = bboxAroundPoint(lat: lat, lng: lng, radiusMeters: radiusMeters);

    final backendPois = <Poi>[];
    for (final dto in nearbyDtos) {
      final p = _poiFromNearbyDto(dto);
      if (p != null) backendPois.add(p);
    }

    var stylePois = const <Poi>[];
    if (mapProbe != null) {
      try {
        await mapProbe.setCamera(
          mb.CameraOptions(
            center: mb.Point(
              coordinates: mb.Position(lng, lat),
            ),
            zoom: 15.0,
            pitch: 0,
            bearing: 0,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 450));
        stylePois = await MapboxStylePoiDiscovery.discoverVisiblePois(
          map: mapProbe,
          logicalViewportSize: kDiscoveryViewport,
        );
      } catch (_) {
        stylePois = const [];
      }
    }

    final merged = HybridPoiMerge.mergeBackendAndStyle(
      area: bbox,
      backendPois: backendPois,
      stylePois: stylePois,
    );

    final out = merged
        .map((p) => poiToArPoi(p, lat, lng))
        .toList(growable: false);
    out.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return out;
  }
}
