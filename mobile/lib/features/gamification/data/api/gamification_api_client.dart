import 'dart:developer';

import 'package:dio/dio.dart';

import '../models/gamification_profile_dto.dart';

/// HTTP client for the gamification API.
///
/// Uses the shared [Dio] instance (JwtInterceptor handles Bearer token).
/// Logs full URL + response details with [GAM_API] tag.
class GamificationApiClient {
  final Dio _dio;

  GamificationApiClient(this._dio);

  /// Fetches the authenticated user's gamification profile.
  ///
  /// Throws [FormatException] if response body is not a JSON map
  /// (caught by [GamificationRepository] → `GamificationError`).
  Future<GamificationProfileDto> fetchProfile() async {
    const path = '/users/me/gamification';
    final fullUrl = '${_dio.options.baseUrl}$path';
    log('[GAM_API] GET $fullUrl');

    final response = await _dio.get<dynamic>(path);

    final status = response.statusCode;
    final data = response.data;
    final dataType = data.runtimeType;
    log('[GAM_API] status=$status type=$dataType url=$fullUrl');

    if (data is! Map<String, dynamic>) {
      throw FormatException(
        'Expected Map<String, dynamic> from $fullUrl, got $dataType',
      );
    }

    return GamificationProfileDto.fromJson(data);
  }
}
