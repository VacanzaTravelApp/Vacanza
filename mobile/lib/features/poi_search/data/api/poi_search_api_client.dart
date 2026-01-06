import 'dart:developer';
import 'package:dio/dio.dart';

import 'poi_search_in_area_request_dto.dart';
import 'poi_search_in_area_response_dto.dart';
import '../models/selected_area.dart';

/// POI Search-in-Area API Client
/// Endpoint: POST /pois/search-in-area
///
/// NOTE:
/// - Bu class sadece HTTP + JSON parse yapar.
/// - Error mapping repository katmanında yapılır (tek nokta).
class PoiSearchApiClient {
  final Dio _dio;

  const PoiSearchApiClient(this._dio);

  Future<PoiSearchInAreaResponseDto> searchInArea({
    required SelectedArea area,
    List<String>? categories,
    int page = 0,
    int? limit,
    PoiSort? sort,
  }) async {
    final req = PoiSearchInAreaRequestDto(
      area: area,
      categories: categories,
      page: page,
      limit: limit,
      sort: sort,
    );

    final body = req.toJson();
    log('[PoiSearchApiClient] POST /pois/search-in-area body=$body');

    final res = await _dio.post(
      '/pois/search-in-area',
      data: body,
      // ✅ endpoint auth istiyor (skipAuth yok)
    );

    log('[PoiSearchApiClient] status=${res.statusCode} data=${res.data}');

    final data = res.data;

    if (data is Map<String, dynamic>) {
      return PoiSearchInAreaResponseDto.fromJson(data);
    }
    if (data is Map) {
      return PoiSearchInAreaResponseDto.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    throw const FormatException('Invalid response body');
  }
}