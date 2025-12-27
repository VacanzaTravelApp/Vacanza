import 'package:dio/dio.dart';
import 'package:mobile/core/network/jwt_interceptor.dart';
import 'package:mobile/features/auth/data/storage/secure_storage_service.dart';

/// Uygulamanın TEK ortak Dio instance'ını üretir.
/// - baseUrl burada tanımlanır
/// - JwtInterceptor burada eklenir
Dio createAppDio({required SecureStorageService storage}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://165.232.69.83:9002',
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