import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:mobile/core/navigation/navigation_service.dart';
import 'package:mobile/features/auth/data/storage/secure_storage_service.dart';

class JwtInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final Dio _dio;

  static bool _handlingUnauthorized = false;

  JwtInterceptor({
    required SecureStorageService storage,
    required Dio dio,
  })  : _storage = storage,
        _dio = dio;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final accessToken = await _storage.readAccessToken();

      final tokenOk = accessToken != null &&
          accessToken.trim().isNotEmpty &&
          accessToken.trim().toLowerCase() != 'null';

      if (tokenOk) {
        options.headers['Authorization'] = 'Bearer ${accessToken!.trim()}';
      }
    } catch (_) {}

    log('[JwtInterceptor] REQ path=${options.path} hasAuth=${options.headers['Authorization'] != null}');
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;

    log('[JwtInterceptor] ERROR status=$status path=$path');

    if (status != 401) {
      handler.next(err);
      return;
    }

    // Bu request "beni logout etme" diyorsa -> sadece hatayı geçir
    final noAutoLogout = err.requestOptions.extra['noAutoLogout'] == true;
    if (noAutoLogout) {
      handler.next(err);
      return;
    }

    // Auth endpointleri 401 dönerse burada refresh/logout yapma
    final isAuthCall = path.startsWith('/auth');
    if (isAuthCall) {
      handler.next(err);
      return;
    }

    // Authorization header yoksa -> session expired sanma
    final authHeader = err.requestOptions.headers['Authorization'];
    final hasAuthHeader =
        authHeader != null && authHeader.toString().trim().isNotEmpty;
    if (!hasAuthHeader) {
      handler.next(err);
      return;
    }

    // Aynı request ikinci kez 401 yediyse (retry sonrası) -> artık logout
    final alreadyRetried = err.requestOptions.extra['__retried'] == true;
    if (alreadyRetried) {
      await _forceLogout();
      handler.next(err);
      return;
    }

    // Aynı anda birden fazla 401 gelirse tek thread handle etsin
    if (_handlingUnauthorized) {
      handler.next(err);
      return;
    }

    _handlingUnauthorized = true;

    try {
      // 1) Firebase token'ı FORCE refresh et
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user == null) {
        await _forceLogout();
        handler.next(err);
        return;
      }

      final newToken = await user.getIdToken(true); // String? olabilir
      final token = newToken?.trim();

      if (token == null || token.isEmpty) {
        await _forceLogout();
        handler.next(err);
        return;
      }

      await _storage.writeAccessToken(token);

      final retriedOptions = _cloneOptions(err.requestOptions);
      retriedOptions.extra['__retried'] = true;
      retriedOptions.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.fetch(retriedOptions);
      handler.resolve(response);
      return;
      return;
    } catch (e) {
      // Refresh/Retry patladı -> logout
      await _forceLogout();
      handler.next(err);
      return;
    } finally {
      _handlingUnauthorized = false;
    }
  }

  RequestOptions _cloneOptions(RequestOptions requestOptions) {
    return RequestOptions(
      path: requestOptions.path,
      method: requestOptions.method,
      baseUrl: requestOptions.baseUrl,
      data: requestOptions.data,
      queryParameters: Map<String, dynamic>.from(requestOptions.queryParameters),
      headers: Map<String, dynamic>.from(requestOptions.headers),
      extra: Map<String, dynamic>.from(requestOptions.extra),
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
      followRedirects: requestOptions.followRedirects,
      listFormat: requestOptions.listFormat,
      maxRedirects: requestOptions.maxRedirects,
      persistentConnection: requestOptions.persistentConnection,
      receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
      receiveTimeout: requestOptions.receiveTimeout,
      requestEncoder: requestOptions.requestEncoder,
      responseDecoder: requestOptions.responseDecoder,
      sendTimeout: requestOptions.sendTimeout,
      validateStatus: requestOptions.validateStatus,
    );
  }

  Future<void> _forceLogout() async {
    try {
      await _storage.clearSession();
      await fb.FirebaseAuth.instance.signOut();
    } catch (_) {}

    try {
      NavigationService.showSnackBar('Session expired. Please login again.');
    } catch (_) {}

    try {
      NavigationService.resetToLogin();
    } catch (_) {}
  }
}