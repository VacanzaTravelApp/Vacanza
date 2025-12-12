import 'package:dio/dio.dart';
import 'package:mobile/features/auth/data/storage/secure_storage_service.dart';

/// JWT access token'i her outbound request'e otomatik olarak ekleyen interceptor.
///
/// Amaç:
///  - Her istekte elle "Authorization: Bearer ..." header'ı eklemek zorunda kalmamak
///  - Tüm protected endpoint'lerin aynı yerden, merkezi şekilde token almasını sağlamak
///
/// NOT:
///  - Şu an sadece header ekleme işini yapıyor.
///  - 401 yakalayıp otomatik logout / refresh mekanizması VACANZA-88 kapsamına girecek.
class JwtInterceptor extends Interceptor {
  final SecureStorageService _storage;

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
      // Storage okurken bir hata olursa:
      //  - Uygulamayı kırmıyoruz
      //  - Sadece header eklememiş oluyoruz
      //  - İstek yine de gitmeye devam ediyor
    }

    // İsteği bir sonraki aşamaya (Dio pipeline) gönder.
    handler.next(options);
  }

// onError / onResponse tarafında şimdilik JWT ile ilgili özel bir işlem yok.
// 401 durumunda otomatik logout / redirect işleri VACANZA-88'de ele alınacak.
}