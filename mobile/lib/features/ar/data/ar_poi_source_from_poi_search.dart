import 'dart:math' as math;

import 'package:mobile/features/poi_search/data/api/poi_search_in_area_response_dto.dart';
import 'package:mobile/features/poi_search/data/models/selected_area.dart';
import 'package:mobile/features/poi_search/data/repositories/poi_search_repository.dart';

import '../domain/models/ar_poi.dart';
import '../domain/services/ar_poi_source.dart';
import 'geospatial_utils.dart';

class ArPoiSourceFromPoiSearch implements ArPoiSource {
  final PoiSearchRepository _poiRepo;

  const ArPoiSourceFromPoiSearch(this._poiRepo);

  @override
  Future<List<ArPoi>> getNearbyArPois({
    required double lat,
    required double lng,
    List<String>? categories,
    double? radiusMeters,
  }) async {
    final effectiveRadius = (radiusMeters ?? 500).clamp(50, 2000).toDouble();

    // Basit bir bbox alanı oluştur (approx) — backend zaten geospatial filtreyi daha iyi yapabilir.
    final bbox = _buildApproxBbox(
      lat: lat,
      lng: lng,
      radiusMeters: effectiveRadius,
    );

    final PoiSearchInAreaResponseDto res = await _poiRepo.searchInArea(
      area: bbox,
      categories: categories,
      page: 0,
      limit: 50,
      sort: null,
    );

    final out = <ArPoi>[];

    for (final poi in res.pois) {
      if (!poi.isEligibleForBackendCheckin) continue;
      final d = distanceMeters(
        lat1: lat,
        lng1: lng,
        lat2: poi.latitude,
        lng2: poi.longitude,
      );

      final b = bearingDegrees(
        lat1: lat,
        lng1: lng,
        lat2: poi.latitude,
        lng2: poi.longitude,
      );

      out.add(
        ArPoi(
          id: poi.poiId,
          name: poi.name,
          categoryKey: poi.category,
          distanceMeters: d,
          bearingDegrees: b,
        ),
      );
    }

    // Yakın olanları öne al, overlay tarafında clutter azaltmak için sayıyı sınırlayabiliriz.
    out.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    return out.length > 30 ? out.sublist(0, 30) : out;
  }

  BboxArea _buildApproxBbox({
    required double lat,
    required double lng,
    required double radiusMeters,
  }) {
    // Yaklaşık: 1 derece enlem ~111 km, boylam için cos(lat).
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
}

