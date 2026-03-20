import 'package:dio/dio.dart';

import '../domain/models/ar_poi.dart';
import '../domain/services/ar_poi_source.dart';
import 'ar_nearby_poi_api_client.dart';
import 'geospatial_utils.dart';

class ArPoiSourceFromBackendNearby implements ArPoiSource {
  final ArNearbyPoiApiClient _apiClient;
  final ArPoiSource _fallback;

  const ArPoiSourceFromBackendNearby({
    required ArNearbyPoiApiClient apiClient,
    required ArPoiSource fallback,
  }) : _apiClient = apiClient,
       _fallback = fallback;

  @override
  Future<List<ArPoi>> getNearbyArPois({
    required double lat,
    required double lng,
    List<String>? categories,
    double? radiusMeters,
  }) async {
    final effectiveRadius = (radiusMeters ?? 600).clamp(50, 2000).toDouble();

    try {
      final dtos = await _apiClient.getNearbyPois(
        lat: lat,
        lng: lng,
        radiusMeters: effectiveRadius,
        categories: categories,
        limit: 40,
      );

      final out = <ArPoi>[];
      for (final dto in dtos) {
        final b = bearingDegrees(
          lat1: lat,
          lng1: lng,
          lat2: dto.latitude,
          lng2: dto.longitude,
        );

        out.add(
          ArPoi(
            id: dto.poiId,
            name: dto.name,
            categoryKey: dto.category,
            distanceMeters: dto.distanceMeters,
            bearingDegrees: b,
          ),
        );
      }

      // Backend already sorts by distance, but keep a safety sort.
      out.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      return out;
    } on DioException catch (e) {
      final sc = e.response?.statusCode;
      if (sc == 404 || sc == 501 || sc == 405) {
        return _fallback.getNearbyArPois(
          lat: lat,
          lng: lng,
          categories: categories,
          radiusMeters: radiusMeters,
        );
      }
      rethrow;
    } on FormatException {
      return _fallback.getNearbyArPois(
        lat: lat,
        lng: lng,
        categories: categories,
        radiusMeters: radiusMeters,
      );
    }
  }
}

