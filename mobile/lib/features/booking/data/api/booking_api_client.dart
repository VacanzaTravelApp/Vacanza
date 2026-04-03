import 'dart:developer';

import 'package:dio/dio.dart';

import '../models/accommodation_option.dart';
import '../models/accommodation_search_request.dart';
import '../models/airport_suggestion.dart';
import '../models/transport_option.dart';
import '../models/transport_search_request.dart';

/// UC1.8-MOB4 — HTTP client for booking search endpoints.
///
/// Uses the shared [Dio] instance (JwtInterceptor handles Bearer token).
/// Logs with [BOOKING_API] tag.
class BookingApiClient {
  final Dio _dio;

  BookingApiClient(this._dio);

  /// Airport / city autocomplete for flight search.
  ///
  /// `GET /bookings/airports/search?q=...` — `q` must be at least 2 characters.
  Future<List<AirportSuggestion>> searchAirports(String query) async {
    final q = query.trim();
    final fullUrl =
        '${_dio.options.baseUrl}/bookings/airports/search?q=${Uri.encodeQueryComponent(q)}';
    log('[BOOKING_API] GET $fullUrl');

    final response = await _dio.get<dynamic>(
      '/bookings/airports/search',
      queryParameters: {'q': q},
    );

    final status = response.statusCode;
    final data = response.data;
    log('[BOOKING_API] airports status=$status type=${data.runtimeType}');

    if (data is! List) {
      throw FormatException(
        'Expected List from $fullUrl, got ${data.runtimeType}',
      );
    }

    final results = <AirportSuggestion>[];
    for (var i = 0; i < data.length; i++) {
      final raw = data[i];
      if (raw is! Map<String, dynamic>) {
        log('[BOOKING_API] airports item[$i] skip type=${raw.runtimeType}');
        continue;
      }
      try {
        results.add(AirportSuggestion.fromJson(raw));
      } catch (e) {
        log('[BOOKING_API] airports parse error at $i: $e');
      }
    }
    log('[BOOKING_API] airports count=${results.length}');
    return results;
  }

  /// Searches accommodations.
  ///
  /// `POST /bookings/accommodations/search`
  ///
  /// Returns parsed list. Throws [DioException] on HTTP errors,
  /// [FormatException] if response body is not a JSON list.
  Future<List<AccommodationOption>> searchAccommodations(
    AccommodationSearchRequest request,
  ) async {
    final fullUrl =
        '${_dio.options.baseUrl}/bookings/accommodations/search';
    final body = request.toJson();
    log('[BOOKING_API] POST $fullUrl body=$body');
    final response = await _dio.post<dynamic>(
      '/bookings/accommodations/search',
      data: body,
    );

    final status = response.statusCode;
    final data = response.data;
    log('[BOOKING_API] status=$status type=${data.runtimeType} url=$fullUrl');

    // ── UC1.8 diagnostics: raw shape inspection ─────────────────
    log('[UC1_8_DEBUG] accommodations status=$status type=${data.runtimeType}');
    if (data is List) {
      log('[UC1_8_DEBUG] accommodations list length=${data.length}');
      if (data.isNotEmpty && data.first is Map<String, dynamic>) {
        final first = data.first as Map<String, dynamic>;
        log('[UC1_8_DEBUG] accommodations first keys=${first.keys.toList()}');
      }
    } else if (data is Map<String, dynamic>) {
      log('[UC1_8_DEBUG] accommodations map keys=${data.keys.toList()}');
      for (final key in ['results', 'items', 'data']) {
        final value = data[key];
        if (value is List) {
          log('[UC1_8_DEBUG] accommodations nested list under "$key" length=${value.length}');
        }
      }
    }

    if (data is! List) {
      throw FormatException(
        'Expected List from $fullUrl, got ${data.runtimeType}',
      );
    }

    // ── TEMP DEBUG: budget / pricing inspection ─────────────────
    log('[BUDGET_DEBUG] REQUEST: query=${body['query']} '
        'dates=${body['checkInDate']}→${body['checkOutDate']} '
        'adults=${body['adults']} budget=${body['budget']} '
        'sort=${body['sortBy']}');

    for (var i = 0; i < data.length && i < 3; i++) {
      log('[BUDGET_DEBUG] RAW item[$i]: ${data[i]}');
    }

    final results = <AccommodationOption>[];
    for (var i = 0; i < data.length; i++) {
      final raw = data[i];
      if (raw is! Map<String, dynamic>) {
        log('[UC1_8_DEBUG] accommodations item[$i] is not Map, type=${raw.runtimeType}');
        continue;
      }
      try {
        results.add(AccommodationOption.fromJson(raw));
      } catch (e, st) {
        log('[UC1_8_DEBUG] accommodations parse error at index=$i error=$e '
            'keys=${raw.keys.toList()}');
        log('[UC1_8_DEBUG] accommodations parse stack=$st');
      }
    }

    if (results.isNotEmpty) {
      final prices = results.map((r) => r.price).toList();
      prices.sort();
      log('[BUDGET_DEBUG] count=${results.length} '
          'minPrice=${prices.first} maxPrice=${prices.last}');
      for (final r in results) {
        log('[BUDGET_DEBUG] ${r.hotelId} "${r.hotelName}" '
            'price=${r.price} ${r.currency} rating=${r.rating}');
      }
    }
    // ── END TEMP DEBUG ──────────────────────────────────────────

    log('[BOOKING_API] accommodations count=${results.length}');
    return results;
  }

  /// Searches flights.
  ///
  /// `POST /bookings/transportation/search`
  ///
  /// Returns parsed list. Throws [DioException] on HTTP errors,
  /// [FormatException] if response body is not a JSON list.
  Future<List<TransportOption>> searchFlights(
    TransportSearchRequest request,
  ) async {
    final fullUrl =
        '${_dio.options.baseUrl}/bookings/transportation/search';
    log('[BOOKING_API] POST $fullUrl body=${request.toJson()}');

    final body = request.toJson();
    final response = await _dio.post<dynamic>(
      '/bookings/transportation/search',
      data: body,
    );

    final status = response.statusCode;
    final data = response.data;
    log('[BOOKING_API] status=$status type=${data.runtimeType} url=$fullUrl');

    // ── UC1.8 diagnostics: raw shape inspection ─────────────────
    log('[UC1_8_DEBUG] flights status=$status type=${data.runtimeType}');
    if (data is List) {
      log('[UC1_8_DEBUG] flights list length=${data.length}');
      if (data.isNotEmpty && data.first is Map<String, dynamic>) {
        final first = data.first as Map<String, dynamic>;
        log('[UC1_8_DEBUG] flights first keys=${first.keys.toList()}');
      }
    } else if (data is Map<String, dynamic>) {
      log('[UC1_8_DEBUG] flights map keys=${data.keys.toList()}');
      for (final key in ['results', 'items', 'data']) {
        final value = data[key];
        if (value is List) {
          log('[UC1_8_DEBUG] flights nested list under "$key" length=${value.length}');
        }
      }
    }

    if (data is! List) {
      throw FormatException(
        'Expected List from $fullUrl, got ${data.runtimeType}',
      );
    }

    final results = <TransportOption>[];
    for (var i = 0; i < data.length; i++) {
      final raw = data[i];
      if (raw is! Map<String, dynamic>) {
        log('[UC1_8_DEBUG] flights item[$i] is not Map, type=${raw.runtimeType}');
        continue;
      }
      try {
        results.add(TransportOption.fromJson(raw));
      } catch (e, st) {
        log('[UC1_8_DEBUG] flights parse error at index=$i error=$e '
            'keys=${raw.keys.toList()}');
        log('[UC1_8_DEBUG] flights parse stack=$st');
      }
    }

    log('[BOOKING_API] flights count=${results.length}');
    return results;
  }
}
