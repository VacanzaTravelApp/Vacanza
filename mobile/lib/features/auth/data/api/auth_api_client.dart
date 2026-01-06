import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import 'package:mobile/features/auth/data/models/user_authentication_dto.dart';
import 'package:mobile/features/auth/data/models/user_register_response.dart';

/// Backend auth endpointleri ile HTTP seviyesinde konuşan client.
///
/// Bu class SADECE request atar.
/// - Firebase login/register yapmaz
/// - SecureStorage yazmaz
/// - UI state üretmez
class AuthApiClient {
  final Dio _dio;

  /// Dio dışarıdan verilir ki:
  /// - baseUrl tek olsun
  /// - interceptor tek olsun
  /// - timeout tek olsun
  AuthApiClient({required Dio dio}) : _dio = dio;

  /// REGISTER SYNC
  ///
  /// POST /auth/register
  /// Header: Authorization: Bearer <FIREBASE_ID_TOKEN>
  /// Body: UserInfoRequestDTO (isimler)
  Future<UserRegisterResponse> registerSync({
    required String firebaseIdToken,
    required Map<String, dynamic> body,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: body,
      options: Options(
        headers: {'Authorization': 'Bearer $firebaseIdToken'},
      ),
    );

    if (response.data is Map) {
      return UserRegisterResponse.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    }

    throw Exception('Register response beklenen formatta değil.');
  }

  /// LOGIN + SESSION RESTORE
  ///
  /// GET /auth/login
  /// Header: Authorization: Bearer <FIREBASE_ID_TOKEN>
  Future<UserAuthenticationDTO> loginSync({
    required String firebaseIdToken,
  }) async {
    final response = await _dio.get(
      '/auth/login',
      options: Options(headers: {'Authorization': 'Bearer $firebaseIdToken'}),
    );

// DEBUG
    debugPrint('[AuthApiClient] /auth/login raw: ${response.data}');
    debugPrint('[AuthApiClient] authenticated runtimeType: ${(response.data as Map?)?['authenticated']?.runtimeType}');

    if (response.data is Map) {
      return UserAuthenticationDTO.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    }

    throw Exception('Login response beklenen formatta değil.');
  }
}