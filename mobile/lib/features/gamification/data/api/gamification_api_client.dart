import 'package:dio/dio.dart';

import '../models/gamification_profile_dto.dart';

/// HTTP client for the gamification API.
///
/// Uses the shared [Dio] instance (JwtInterceptor handles Bearer token).
class GamificationApiClient {
  final Dio _dio;

  GamificationApiClient(this._dio);

  /// Fetches the authenticated user's gamification profile.
  ///
  /// Throws [FormatException] if response body is not a JSON map
  /// (caught by [GamificationRepository] → `GamificationError`).
  Future<GamificationProfileDto> fetchProfile() async {
    final response = await _dio.get<dynamic>(
      '/gamification/profile',
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Expected Map<String, dynamic> from /gamification/profile',
      );
    }

    return GamificationProfileDto.fromJson(data);
  }
}
