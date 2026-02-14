import 'package:dio/dio.dart';

import '../models/auto_checkin_request_dto.dart';
import '../models/auto_checkin_response_dto.dart';

/// HTTP client for the check-in endpoints.
///
/// Uses the shared [Dio] instance which already has [JwtInterceptor]
/// attached — Bearer token is handled automatically.
class CheckinApiClient {
  final Dio _dio;

  CheckinApiClient(this._dio);

  /// Sends an auto check-in request.
  ///
  /// Throws [DioException] on network/server errors.
  Future<AutoCheckinResponseDto> autoCheckin(
    AutoCheckinRequestDto request,
  ) async {
    final response = await _dio.post(
      '/checkins/auto',
      data: request.toJson(),
    );

    return AutoCheckinResponseDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
