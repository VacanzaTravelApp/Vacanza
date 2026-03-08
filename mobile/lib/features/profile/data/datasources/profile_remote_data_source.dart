import 'dart:convert';
import 'dart:developer' as dev;

import 'package:dio/dio.dart';

import '../dto/check_in_dto.dart';
import '../dto/travel_stats_dto.dart';
import '../dto/user_preferences_dto.dart';
import '../dto/user_profile_dto.dart';

/// Remote data source for profile APIs. Uses shared [Dio] (Bearer token via JwtInterceptor).
/// Throws [DioException] or [FormatException] on failure.
class ProfileRemoteDataSource {
  final Dio _dio;

  ProfileRemoteDataSource(this._dio);

  static const _basePath = '/users/me';

  Future<UserProfileDto> getProfile() async {
    final response = await _dio.get<dynamic>('$_basePath/profile');
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw FormatException(
        'Expected Map from $_basePath/profile, got ${data.runtimeType}',
      );
    }
    return UserProfileDto.fromJson(data);
  }

  Future<UserProfileDto> updateProfile(Map<String, dynamic> partial) async {
    final response = await _dio.put<dynamic>(
      '$_basePath/profile',
      data: partial,
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw FormatException(
        'Expected Map from PUT $_basePath/profile, got ${data.runtimeType}',
      );
    }
    return UserProfileDto.fromJson(data);
  }

  Future<UserPreferencesDto> getPreferences() async {
    final response = await _dio.get<dynamic>('$_basePath/preferences');
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw FormatException(
        'Expected Map from $_basePath/preferences, got ${data.runtimeType}',
      );
    }
    return UserPreferencesDto.fromJson(data);
  }

  Future<UserPreferencesDto> updatePreferences(Map<String, dynamic> partial) async {
    const method = 'PUT';
    final path = '$_basePath/preferences';
    final bodyJson = jsonEncode(partial);
    // Token is in Authorization header (set by interceptor); not logged.
    dev.log('$method $path body: $bodyJson', name: 'ProfileRemote');
    try {
      final response = await _dio.put<dynamic>(path, data: partial);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw FormatException(
          'Expected Map from PUT $_basePath/preferences, got ${data.runtimeType}',
        );
      }
      return UserPreferencesDto.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        dev.log('PUT preferences 400 response: ${e.response?.data}', name: 'ProfileRemote');
      }
      rethrow;
    }
  }

  Future<TravelStatsDto> getStats() async {
    final response = await _dio.get<dynamic>('$_basePath/stats');
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw FormatException(
        'Expected Map from $_basePath/stats, got ${data.runtimeType}',
      );
    }
    return TravelStatsDto.fromJson(data);
  }

  Future<List<CheckInDto>> getCheckIns() async {
    final response = await _dio.get<dynamic>('$_basePath/checkins');
    final data = response.data;
    if (data is! List) {
      throw FormatException(
        'Expected List from $_basePath/checkins, got ${data.runtimeType}',
      );
    }
    return data
        .map((e) => CheckInDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
