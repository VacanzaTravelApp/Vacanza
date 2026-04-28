import 'dart:convert';

import 'package:dio/dio.dart';

import 'poi_mapbox_stream_event.dart';
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
   // log('[PoiSearchApiClient] POST /pois/search-in-area body=$body');

    final res = await _dio.post(
      '/pois/search-in-area',
      data: body,
      // ✅ endpoint auth istiyor (skipAuth yok)
    );

   // log('[PoiSearchApiClient] status=${res.statusCode} data=${res.data}');

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

  /// SSE: `chunk` … `done` (Mapbox tiled progressive search).
  Stream<PoiMapboxStreamEvent> searchInAreaMapboxStream({
    required SelectedArea area,
    List<String>? categories,
    int page = 0,
    int? limit,
    PoiSort? sort,
    CancelToken? cancelToken,
  }) async* {
    final req = PoiSearchInAreaRequestDto(
      area: area,
      categories: categories,
      page: page,
      limit: limit,
      sort: sort,
      mapboxAreaSearch: true,
    );

    final res = await _dio.post<ResponseBody>(
      '/pois/search-in-area/stream',
      data: req.toJson(),
      options: Options(
        responseType: ResponseType.stream,
        headers: {
          'Accept': 'text/event-stream',
        },
      ),
      cancelToken: cancelToken,
    );

    final body = res.data;
    if (body == null) {
      throw const FormatException('Empty stream body');
    }

    await for (final map in _sseJsonMaps(body.stream)) {
      final t = (map['type'] ?? '').toString();
      if (t == 'chunk') {
        yield PoiMapboxStreamChunk.fromJson(map);
      } else if (t == 'done') {
        yield PoiMapboxStreamDone.fromJson(map);
      }
    }
  }

  static Stream<Map<String, dynamic>> _sseJsonMaps(
    Stream<List<int>> byteStream,
  ) async* {
    var buffer = '';
    await for (final chunk in utf8.decoder.bind(byteStream)) {
      buffer += chunk;
      for (;;) {
        final sep = buffer.indexOf('\n\n');
        if (sep < 0) break;
        final rawEvent = buffer.substring(0, sep);
        buffer = buffer.substring(sep + 2);
        for (final line in rawEvent.split('\n')) {
          final t = line.trim();
          if (!t.startsWith('data:')) continue;
          final payload = t.substring(5).trim();
          if (payload.isEmpty) continue;
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            yield decoded;
          } else if (decoded is Map) {
            yield Map<String, dynamic>.from(decoded);
          }
        }
      }
    }
  }
}