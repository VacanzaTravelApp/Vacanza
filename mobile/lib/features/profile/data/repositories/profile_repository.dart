import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/network/backend_error_parser.dart';
import '../datasources/profile_remote_data_source.dart';
import '../models/check_in.dart';
import '../models/travel_stats.dart';
import '../models/user_preferences.dart';
import '../models/user_profile.dart';

/// Domain-level exception for profile operations.
class ProfileException implements Exception {
  final String message;
  const ProfileException(this.message);

  @override
  String toString() => 'ProfileException: $message';
}

/// Wraps [ProfileRemoteDataSource]; returns domain models and maps failures to [ProfileException].
class ProfileRepository {
  final ProfileRemoteDataSource _dataSource;

  ProfileRepository({required ProfileRemoteDataSource dataSource})
      : _dataSource = dataSource;

  Future<UserProfile> getProfile() async {
    try {
      final dto = await _dataSource.getProfile();
      return dto.toDomain();
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on FormatException {
      throw const ProfileException('Invalid response');
    }
  }

  Future<UserProfile> updateProfile(Map<String, dynamic> partial) async {
    try {
      final dto = await _dataSource.updateProfile(partial);
      return dto.toDomain();
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on FormatException {
      throw const ProfileException('Invalid response');
    }
  }

  Future<void> uploadProfilePhoto(String filePath) async {
    try {
      await _dataSource.uploadProfilePhoto(filePath);
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on FormatException catch (e) {
      throw ProfileException(e.message);
    }
  }

  /// `null` when no binary photo (404).
  Future<Uint8List?> fetchProfilePhotoBytes() async {
    try {
      return await _dataSource.fetchProfilePhotoBytes();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> deleteProfilePhoto() async {
    try {
      await _dataSource.deleteProfilePhoto();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<UserPreferences> getPreferences() async {
    try {
      final dto = await _dataSource.getPreferences();
      return dto.toDomain();
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on FormatException {
      throw const ProfileException('Invalid response');
    }
  }

  Future<UserPreferences> updatePreferences(Map<String, dynamic> partial) async {
    try {
      final dto = await _dataSource.updatePreferences(partial);
      return dto.toDomain();
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on FormatException {
      throw const ProfileException('Invalid response');
    }
  }

  Future<TravelStats> getStats() async {
    try {
      final dto = await _dataSource.getStats();
      return dto.toDomain();
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on FormatException {
      throw const ProfileException('Invalid response');
    }
  }

  Future<List<CheckIn>> getCheckIns() async {
    try {
      final list = await _dataSource.getCheckIns();
      return list.map((dto) => dto.toDomain()).toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on FormatException {
      throw const ProfileException('Invalid response');
    }
  }

  ProfileException _mapDioException(DioException e) {
    final status = e.response?.statusCode;
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const ProfileException('Network error');
    }
    if (status == 401 || status == 403) {
      return const ProfileException('Unauthorized');
    }
    if (status == 400) {
      return ProfileException(extractBackendMessage(e));
    }
    if (status != null) {
      return ProfileException('Request failed (status: $status)');
    }
    return const ProfileException('Request failed');
  }
}
