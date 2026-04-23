import 'package:dio/dio.dart';
import 'package:mobile/core/network/jwt_interceptor.dart';
import 'package:mobile/features/auth/data/storage/secure_storage_service.dart';

/// Varsayılan: doğrudan backend (web’in de kullandığı adresle aynı olmalı).
/// API’yi domain üzerinden (443) kullanacaksan: örn.
/// `flutter run --dart-define=VACANZA_API_BASE_URL=https://production.vacanza.app`
const String _kApiBaseUrl = String.fromEnvironment(
  'VACANZA_API_BASE_URL',
  defaultValue: 'http://165.232.69.83:9002',
);

/// Uygulamanın TEK ortak Dio instance'ını üretir.
/// - baseUrl burada tanımlanır
/// - JwtInterceptor burada eklenir
Dio createAppDio({required SecureStorageService storage}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _kApiBaseUrl.endsWith('/')
          ? _kApiBaseUrl.substring(0, _kApiBaseUrl.length - 1)
          : _kApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  );

  dio.interceptors.add(
    JwtInterceptor(
      storage: storage,
      dio: dio, // ✅ retry için aynı dio gerekli
    ),
  );

  return dio;
}