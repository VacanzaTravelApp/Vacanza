import 'dart:developer';

import 'package:dio/dio.dart';

import '../api/gamification_api_client.dart';
import '../models/gamification_profile_dto.dart';
import '../models/mock_profile.dart';

/// Domain-level exception for gamification operations.
class GamificationException implements Exception {
  final String message;
  const GamificationException(this.message);

  @override
  String toString() => 'GamificationException: $message';
}

/// Result wrapper that indicates whether data is real or mock.
class GamificationResult {
  final GamificationProfileDto profile;
  final bool isMock;
  const GamificationResult({required this.profile, this.isMock = false});
}

/// Wraps [GamificationApiClient] and maps [DioException] to
/// [GamificationException] for clean domain-level error handling.
///
/// Returns mock data on 404 (backend not deployed yet).
class GamificationRepository {
  final GamificationApiClient _apiClient;

  GamificationRepository({required GamificationApiClient apiClient})
      : _apiClient = apiClient;

  /// Fetches the gamification profile.
  ///
  /// On 404, returns [GamificationResult] with `isMock: true` and mock data.
  /// On other errors, throws [GamificationException].
  Future<GamificationResult> getProfile() async {
    try {
      final profile = await _apiClient.fetchProfile();
      return GamificationResult(profile: profile);
    } on DioException catch (e) {
      log('[GamificationRepo] DioException: ${e.type} ${e.message}');

      // 404 → backend not ready, use mock fallback
      final status = e.response?.statusCode;
      if (status == 404) {
        log('[GamificationRepo] 404 → returning mock profile');
        return GamificationResult(
          profile: mockGamificationProfile(),
          isMock: true,
        );
      }

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
      log('[GamificationRepo] FormatException: $e');
      throw const GamificationException('Invalid response');
    }
  }
}
