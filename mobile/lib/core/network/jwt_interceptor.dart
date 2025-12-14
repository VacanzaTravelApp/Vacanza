import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:mobile/core/navigation/navigation_service.dart';
import 'package:mobile/features/auth/data/storage/secure_storage_service.dart';

/// JWT access token'i her outbound request'e otomatik olarak ekleyen interceptor.
///
/// Amaç:
///  - Her istekte elle "Authorization: Bearer ..." header'ı eklemek zorunda kalmamak
///  - 401 gelirse global yakalayıp kullanıcıyı session expired gibi logout etmek
///
/// NOT:
///  - Refresh mekanizması (token yenileme) bu sprintte yok.
///  - 401 -> direkt logout + Login'e yönlendirme yapıyoruz.
class JwtInterceptor extends Interceptor {
  final SecureStorageService _storage;

  /// 401'lerde aynı anda birden fazla istek patlarsa
  /// (örn. 3 request aynı anda 401 dönerse) user'ı 3 kere redirect etmeyelim.
  static bool _handlingUnauthorized = false;

  JwtInterceptor({
    required SecureStorageService storage,
  }) : _storage = storage;

  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    try {
      // SecureStorage içinden access_token'ı oku.
      final accessToken = await _storage.readAccessToken();

      // Token null değil ve boş değilse Authorization header'ına ekle.
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    } catch (_) {
      // Storage okurken hata olursa request'i kırmıyoruz.
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;

    // 401 dışı hataları olduğu gibi devam ettir.
    if (status != 401) {
      handler.next(err);
      return;
    }

    // Auth endpointleri (login/register) 401 dönerse
    // kullanıcıyı logout/redirect etmek istemeyebiliriz.
    // Çünkü login zaten hata döndürüp UI'da gösterilecek.
    final path = err.requestOptions.path;
    final isAuthCall = path.startsWith('/auth');

    if (isAuthCall) {
      handler.next(err);
      return;
    }

    // Aynı anda birden fazla 401 gelirse tek sefer handle et.
    if (_handlingUnauthorized) {
      handler.next(err);
      return;
    }

    _handlingUnauthorized = true;

    try {
      // 1) Local tokenları temizle (access/refresh)
      await _storage.clearSession();

      // 2) Firebase oturumunu kapat
      await fb.FirebaseAuth.instance.signOut();

      // 3) Kullanıcıya sakin bir "session expired" hissi ver
      NavigationService.showSnackBar('Session expired. Please login again.');

      // 4) Stack temizleyerek Login'e yönlendir
      NavigationService.resetToLogin();
    } catch (_) {
      // Herhangi bir yerde hata çıksa bile crash istemiyoruz.
      // Yine de yönlendirmeyi dene.
      NavigationService.resetToLogin();
    } finally {
      _handlingUnauthorized = false;
    }

    handler.next(err);
  }
}