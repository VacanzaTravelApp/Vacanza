import 'dart:developer';

import 'package:dio/dio.dart';

import '../api/booking_api_client.dart';
import '../models/accommodation_option.dart';
import '../models/accommodation_search_request.dart';
import '../models/transport_option.dart';
import '../models/transport_search_request.dart';

/// Domain-level exception for booking operations.
class BookingException implements Exception {
  final String message;
  const BookingException(this.message);

  @override
  String toString() => 'BookingException: $message';
}

/// Wraps [BookingApiClient] and maps [DioException] to
/// [BookingException] for clean domain-level error handling.
///
/// Logs diagnostics with [BOOKING_REPO] tag.
class BookingRepository {
  final BookingApiClient _apiClient;

  BookingRepository({required BookingApiClient apiClient})
      : _apiClient = apiClient;

  /// Searches hotels; throws [BookingException] on error.
  /// Returns empty list on 200 + [] (not an error).
  Future<List<AccommodationOption>> searchHotels(
    AccommodationSearchRequest request,
  ) async {
    try {
      return await _apiClient.searchAccommodations(request);
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on FormatException catch (e) {
      log('[BOOKING_REPO] FormatException: $e');
      throw const BookingException('Unexpected server response');
    }
  }

  /// Searches flights; throws [BookingException] on error.
  /// Returns empty list on 200 + [] (not an error).
  Future<List<TransportOption>> searchFlights(
    TransportSearchRequest request,
  ) async {
    try {
      return await _apiClient.searchFlights(request);
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on FormatException catch (e) {
      log('[BOOKING_REPO] FormatException: $e');
      throw const BookingException('Unexpected server response');
    }
  }

  /// Maps [DioException] to [BookingException] with contract-aligned messages.
  BookingException _mapDioException(DioException e) {
    final status = e.response?.statusCode;
    log('[BOOKING_REPO] DioException type=${e.type} '
        'status=$status message=${e.message}');

    // Network / timeout errors — matches GamificationRepository wording
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const BookingException('Network error');
    }

    // HTTP status mapping
    if (status == 400) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['message'] != null) {
        return BookingException(data['message'].toString());
      }
      return const BookingException('Invalid search parameters');
    }

    if (status == 401) {
      return const BookingException('Unauthorized');
    }

    if (status == 500) {
      // Backend wraps SerpApi/Google Flights errors into 500.
      return const BookingException(
        'Search is temporarily unavailable, please try again later.',
      );
    }

    if (status == 502) {
      return const BookingException('Search service temporarily unavailable');
    }

    if (status != null) {
      return BookingException('Request failed (status: $status)');
    }

    return const BookingException('Request failed');
  }
}
