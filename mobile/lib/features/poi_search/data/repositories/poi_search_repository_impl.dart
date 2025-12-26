import 'dart:developer';
import 'package:dio/dio.dart';

import '../api/poi_search_api_client.dart';
import '../api/poi_search_in_area_request_dto.dart';
import '../api/poi_search_in_area_response_dto.dart';
import '../models/selected_area.dart';
import 'poi_search_repository.dart';
import 'poi_search_repository_exception.dart';

/// Concrete repository implementation.
/// - UI/Bloc Dio görmez
/// - Error mapping tek noktada burada yapılır
class PoiSearchRepositoryImpl implements PoiSearchRepository {
  final PoiSearchApiClient _api;

  const PoiSearchRepositoryImpl(this._api);

  @override
  Future<PoiSearchInAreaResponseDto> searchInArea({
    required SelectedArea area,
    List<String>? categories,
    int page = 0,
    int? limit,
    PoiSort? sort,
  }) async {
    final normalizedCategories = _normalizeCategories(categories);

    try {
      return await _api.searchInArea(
        area: area,
        categories: normalizedCategories,
        page: page,
        limit: limit,
        sort: sort,
      );
    } on DioException catch (e) {
      final rawMessage = _extractBackendMessage(e);
      final parsed = parseCodeMessage(rawMessage);

      log(
        '[PoiSearchRepository] DioException status=${e.response?.statusCode} raw="$rawMessage"',
      );

      throw PoiSearchRepositoryException(
        code: parsed.code,
        message: parsed.message,
      );
    } on FormatException catch (e) {
      throw PoiSearchRepositoryException(
        code: 'INVALID_RESPONSE',
        message: e.message,
      );
    } catch (e) {
      throw const PoiSearchRepositoryException(
        code: 'UNKNOWN_ERROR',
        message: 'Request failed',
      );
    }
  }

  /// Backend error body'sinden "message" çekmeye çalışır.
  /// Yoksa fallback üretir.
  String _extractBackendMessage(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    if (data is String && data.trim().isNotEmpty) return data;

    if (status != null) return 'HTTP_$status: Empty error body';
    return e.message ?? 'UNKNOWN_ERROR: Request failed';
  }

  /// Case-insensitive olsun diye: trim + lowercase + uniq.
  /// Boş kalırsa null döner (backend: filtre yok).
  List<String>? _normalizeCategories(List<String>? categories) {
    if (categories == null || categories.isEmpty) return null;

    final out = <String>[];
    final seen = <String>{};

    for (final c in categories) {
      final s = c.trim().toLowerCase();
      if (s.isEmpty) continue;
      if (seen.add(s)) out.add(s);
    }

    return out.isEmpty ? null : out;
  }
}