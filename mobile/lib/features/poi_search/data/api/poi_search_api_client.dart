import 'dart:developer';

import 'package:dio/dio.dart';

import 'package:mobile/features/poi_search/data/api/poi_search_in_area_request_dto.dart';
import 'package:mobile/features/poi_search/data/api/poi_search_in_area_response_dto.dart';
import 'package:mobile/features/poi_search/data/models/selected_area.dart';

/// POI Search-in-Area API Client
/// Endpoint: POST /pois/search-in-area
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

    try {

      log('[PoiSearchApiClient] POST /pois/search-in-area body=${req.toJson()}');
      final res = await _dio.post(

        "/pois/search-in-area",
        data: req.toJson(),
        // ✅ NOT: Bu endpoint auth istiyor -> skipAuth YOK
      );
      log('[PoiSearchApiClient] status=${res.statusCode} data=${res.data}');
      final data = res.data;

      // ✅ güvenli parse
      if (data is Map<String, dynamic>) {
        return PoiSearchInAreaResponseDto.fromJson(data);
      }
      if (data is Map) {
        return PoiSearchInAreaResponseDto.fromJson(
          Map<String, dynamic>.from(data as Map),
        );
      }

      throw const PoiSearchApiException(
        code: "INVALID_RESPONSE",
        message: "Invalid response body",
        raw: null,
      );
    } on DioException catch (e) {
      final message = _extractMessage(e);
      final code = _extractCode(message);
      throw PoiSearchApiException(code: code, message: message, raw: e);
    }
  }

  String _extractMessage(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map && data["message"] is String) {
      return data["message"] as String;
    }
    if (data is String && data.trim().isNotEmpty) return data;

    if (status != null) return "HTTP_$status: Empty error body";
    return e.message ?? "UNKNOWN_ERROR: Request failed";
  }

  String _extractCode(String message) {
    final i = message.indexOf(":");
    if (i <= 0) return "UNKNOWN_ERROR";
    return message.substring(0, i).trim();
  }
}

class PoiSearchApiException implements Exception {
  final String code;
  final String message;
  final DioException? raw;

  const PoiSearchApiException({
    required this.code,
    required this.message,
    required this.raw,
  });

  @override
  String toString() => "PoiSearchApiException($code): $message";
}