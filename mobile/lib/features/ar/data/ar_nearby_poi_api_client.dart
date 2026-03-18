import 'package:dio/dio.dart';

import 'ar_nearby_poi_dto.dart';

class ArNearbyPoiApiClient {
  final Dio _dio;

  const ArNearbyPoiApiClient(this._dio);

  Future<List<ArNearbyPoiDto>> getNearbyPois({
    required double lat,
    required double lng,
    double radiusMeters = 600,
    List<String>? categories,
    int limit = 40,
  }) async {
    final String? categoriesCsv =
        categories == null || categories.isEmpty ? null : categories.join(',');

    final res = await _dio.get(
      '/pois/nearby',
      queryParameters: <String, dynamic>{
        'lat': lat,
        'lng': lng,
        'radiusMeters': radiusMeters,
        if (categoriesCsv != null) 'categories': categoriesCsv,
        'limit': limit,
      },
    );

    final data = res.data;
    if (data is! List) {
      throw const FormatException('Expected a JSON array');
    }

    return data
        .whereType<Map>()
        .map((m) => ArNearbyPoiDto.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }
}

