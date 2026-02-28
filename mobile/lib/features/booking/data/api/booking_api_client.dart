import 'dart:developer';

import 'package:dio/dio.dart';

import '../models/accommodation_option.dart';
import '../models/accommodation_search_request.dart';
import '../models/transport_option.dart';
import '../models/transport_search_request.dart';

/// UC1.8-MOB4 — HTTP client for booking search endpoints.
///
/// Uses the shared [Dio] instance (JwtInterceptor handles Bearer token).
/// Logs with [BOOKING_API] tag.
class BookingApiClient {
  final Dio _dio;

  BookingApiClient(this._dio);

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
    log('[BOOKING_API] POST $fullUrl body=${request.toJson()}');

    final response = await _dio.post<dynamic>(
      '/bookings/accommodations/search',
      data: request.toJson(),
    );

    final status = response.statusCode;
    final data = response.data;
    log('[BOOKING_API] status=$status type=${data.runtimeType} url=$fullUrl');

    if (data is! List) {
      throw FormatException(
        'Expected List from $fullUrl, got ${data.runtimeType}',
      );
    }

    // ── TEMP DEBUG: raw JSON inspection ─────────────────────────
    final reqJson = request.toJson();
    log('[BUDGET_DEBUG] REQUEST: city=${reqJson['cityCode']} '
        'dates=${reqJson['checkInDate']}→${reqJson['checkOutDate']} '
        'adults=${reqJson['adults']} budget=${reqJson['budget']} '
        'sort=${reqJson['sortBy']}');

    for (var i = 0; i < data.length && i < 3; i++) {
      log('[BUDGET_DEBUG] RAW item[$i]: ${data[i]}');
    }

    final results = data
        .map((e) => AccommodationOption.fromJson(e as Map<String, dynamic>))
        .toList();

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

    final response = await _dio.post<dynamic>(
      '/bookings/transportation/search',
      data: request.toJson(),
    );

    final status = response.statusCode;
    final data = response.data;
    log('[BOOKING_API] status=$status type=${data.runtimeType} url=$fullUrl');

    if (data is! List) {
      throw FormatException(
        'Expected List from $fullUrl, got ${data.runtimeType}',
      );
    }

    final results = data
        .map((e) => TransportOption.fromJson(e as Map<String, dynamic>))
        .toList();

    log('[BOOKING_API] flights count=${results.length}');
    return results;
  }
}
