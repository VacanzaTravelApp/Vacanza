import 'package:dio/dio.dart';
import 'package:mobile/features/auth/data/storage/secure_storage_service.dart';

/// JWT interceptor (Authorization header injector)
///
/// Amaç:
///  - Her request'te elle "Authorization: Bearer <token>" eklememek
///  - Merkezi şekilde token eklemek
///
/// ÖNEMLİ (Yeni Mantık):
///  - Backend artık kendi JWT'sini üretmüyor.
///  - Bu yüzden Bearer token olarak Firebase'in ürettiği **ID Token** gönderilecek.
///  - Biz bu ID Token'ı şimdilik SecureStorage'da `access_token` key'i altında tutuyoruz.
///    (İleride istersek key adını refactor ederiz ama şu an çalışanı bozmuyoruz.)
///
/// NOT:
///  - 401 yakalama / refresh / otomatik logout gibi işler VACANZA-88'de ele alınacak.
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
      // SecureStorage içinden token oku.
      // Yeni mantıkta bu token: Firebase ID Token.
      final token = await _storage.readAccessToken();

      // Token null değil ve boş değilse Authorization header'ına ekle.
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Storage okurken hata olursa request'i kırmıyoruz.
      // Sadece header eklenmemiş olur.
    }

    handler.next(options);
  }
}