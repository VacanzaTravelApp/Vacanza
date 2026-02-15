import 'dart:developer';

import 'package:dio/dio.dart';

import '../api/gamification_api_client.dart';
import '../models/gamification_profile_dto.dart';

/// Domain-level exception for gamification operations.
class GamificationException implements Exception {
  final String message;
  const GamificationException(this.message);

  @override
  String toString() => 'GamificationException: $message';
}

/// Wraps [GamificationApiClient] and maps [DioException] to
/// [GamificationException] for clean domain-level error handling.
///
/// Logs diagnostics with [GAM_REPO] tag.
class GamificationRepository {
  final GamificationApiClient _apiClient;

  GamificationRepository({required GamificationApiClient apiClient})
      : _apiClient = apiClient;

  /// Fetches the gamification profile; throws [GamificationException] on error.
  Future<GamificationProfileDto> getProfile() async {
    try {
      return await _apiClient.fetchProfile();
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      log('[GAM_REPO] DioException type=${e.type} '
          'status=$status message=${e.message}');

      // Network / timeout errors
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const GamificationException('Network error');
      }

      // HTTP status mapping
      if (status == 401 || status == 403) {
        throw const GamificationException('Unauthorized');
      }
      if (status != null) {
        throw GamificationException('Request failed (status: $status)');
      }

      throw const GamificationException('Request failed');
    } on FormatException catch (e) {
      log('[GAM_REPO] FormatException: $e');
      throw const GamificationException('Invalid response');
    }
  }
}
