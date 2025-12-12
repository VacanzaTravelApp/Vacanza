import 'package:dio/dio.dart';

/// Backend'in /auth endpointleri ile HTTP seviyesinde konuşan client.
///
/// SORUMLULUK:
///  - /auth/login
///  - /auth/register
///
/// İş mantığı BU SINIFTA YOK.
/// Sadece istek atar, cevabı map'ler ve repository'e geri döner.
///
/// ŞU AN:
///  - AuthRepository içinde bu metodları çağıran kod COMMENT'li olacak.
///  - Backend hazır olduğunda commentler kaldırılıp gerçek akış aktif edilecek.
class AuthApiClient {
  final Dio _dio;

  AuthApiClient({Dio? dio})
      : _dio = dio ??
      Dio(
        BaseOptions(
          baseUrl: 'http://10.0.2.2:8080', // TODO: prod URL eklenecek
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

  /// /auth/login çağrısı.
  ///
  /// Beklenen request body:
  ///  {
  ///    "firebaseUid": "...",
  ///    "firebaseIdToken": "..."
  ///  }
  ///
  /// Beklenen response örneği:
  ///  {
  ///    "access_token": "...",
  ///    "refresh_token": "..."
  ///  }
  Future<Map<String, dynamic>> login({
    required String firebaseUid,
    required String firebaseIdToken,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {
        'firebaseUid': firebaseUid,
        'firebaseIdToken': firebaseIdToken,
      },
    );

    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }

    throw Exception('Backend login response beklenen formatta değil.');
  }

  /// /auth/register çağrısı.
  ///
  /// Beklenen body örneği (repository tarafında hazırlanacak):
  ///  {
  ///    "firebaseUid": "...",
  ///    "firebaseIdToken": "...",
  ///    "email": "...",
  ///    "firstName": "...",
  ///    "middleName": "...",
  ///    "lastName": "...",
  ///    "preferredNames": [...]
  ///  }
  ///
  /// Backend'den yine access + refresh token dönmesi bekleniyor.
  Future<Map<String, dynamic>> register({
    required Map<String, dynamic> body,
  }) async {
    final response = await _dio.post('/auth/register', data: body);

    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }

    throw Exception('Backend register response beklenen formatta değil.');
  }
}