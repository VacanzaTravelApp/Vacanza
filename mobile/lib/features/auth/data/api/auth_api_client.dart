import 'package:dio/dio.dart';

import 'package:mobile/features/auth/data/models/auth_backend_result.dart';

/// Backend'in /auth endpointleri ile HTTP seviyesinde konuşan client.
///
/// SORUMLULUK:
///  - Sadece HTTP çağrısı atar.
///  - Authorization header'a Bearer token ekler.
///  - Response'u AuthBackendResult'a mapler.
///
/// İş mantığı (Firebase login/register, storage yazma, fallback vs.) BURADA YOK.
/// O işler AuthRepository'de.
class AuthApiClient {
  final Dio _dio;

  /// ÖNEMLİ:
  /// Dio burada "create" edilmez; dışarıdan verilir.
  ///
  /// Neden?
  /// - Çünkü tek bir Dio instance kullanmak istiyoruz.
  /// - JwtInterceptor, baseUrl, timeout vs. tek yerde yönetilsin.
  /// - Yoksa farklı Dio oluşur → interceptor çalışmaz.
  AuthApiClient({required Dio dio}) : _dio = dio;

  /// POST /auth/login
  ///
  /// Header:
  ///   Authorization: Bearer <firebaseIdToken>
  ///
  /// Body:
  ///   backend ne istiyorsa o (şimdilik boş olabilir)
  ///
  /// Backend döner:
  ///   authenticated + user
  Future<AuthBackendResult> login({
    required String firebaseIdToken,
    Map<String, dynamic>? body,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: body ?? const {},
      options: Options(
        headers: {
          'Authorization': 'Bearer $firebaseIdToken',
        },
      ),
    );

    if (response.data is Map) {
      return AuthBackendResult.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    }

    throw Exception('Backend login response beklenen formatta değil.');
  }

  /// POST /auth/register
  ///
  /// Header:
  ///   Authorization: Bearer <firebaseIdToken>
  ///
  /// Body:
  ///   {
  ///     "email": "...",
  ///     "firstName": "...",
  ///     "middleName": "...",
  ///     "lastName": "...",
  ///     "preferredNames": [...]
  ///   }
  ///
  /// Backend döner:
  ///   authenticated + user
  Future<AuthBackendResult> register({
    required String firebaseIdToken,
    required Map<String, dynamic> body,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: body,
      options: Options(
        headers: {
          'Authorization': 'Bearer $firebaseIdToken',
        },
      ),
    );

    if (response.data is Map) {
      return AuthBackendResult.fromJson(
        (response.data as Map).cast<String, dynamic>(),
      );
    }

    throw Exception('Backend register response beklenen formatta değil.');
  }
}