import 'dart:developer';

import 'package:dio/dio.dart';

import '../api/checkin_api_client.dart';
import '../models/auto_checkin_request_dto.dart';
import '../models/auto_checkin_response_dto.dart';

/// Domain-level repository that wraps [CheckinApiClient].
///
/// Maps [DioException] and other errors into a simple [CheckinFailure]
/// string so the presentation layer never sees Dio types directly.
class CheckinRepository {
  final CheckinApiClient _apiClient;

  CheckinRepository(this._apiClient);

  /// Calls `POST /users/me/checkins/auto` and returns the parsed response.
  ///
  /// On failure, throws a [CheckinException] with a user-friendly message.
  Future<AutoCheckinResponseDto> autoCheckin({
    required double latitude,
    required double longitude,
    required List<String> candidatePoiIds,
  }) async {
    try {
      final dto = AutoCheckinRequestDto(
        latitude: latitude,
        longitude: longitude,
        candidatePoiIds: candidatePoiIds,
      );
      return await _apiClient.autoCheckin(dto);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      log('[CheckinRepository] DioException statusCode=$statusCode '
          'message=${e.message}');

      if (statusCode == 429) {
        throw CheckinException('Too many requests. Please wait a moment.');
      }
      if (statusCode == 401) {
        // JwtInterceptor should have handled this, but guard anyway
        throw CheckinException('Authentication error. Please log in again.');
      }
      throw CheckinException(
        e.message ?? 'Network error. Check-in failed.',
      );
    } on FormatException catch (e) {
      log('[CheckinRepository] FormatException: $e');
      throw CheckinException('Invalid response from server.');
    } catch (e) {
      log('[CheckinRepository] Unexpected error: $e');
      throw CheckinException('Check-in failed unexpectedly.');
    }
  }
}

/// Simple exception type for check-in domain errors.
class CheckinException implements Exception {
  final String message;
  const CheckinException(this.message);

  @override
  String toString() => 'CheckinException: $message';
}
