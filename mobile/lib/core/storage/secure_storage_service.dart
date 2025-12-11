// lib/core/storage/secure_storage_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Uygulama genelinde güvenli token saklama işlemlerini yöneten servis.
///
/// Burada sadece:
///  - access_token
///  - refresh_token
///
/// için helper metotlar yazıyoruz.
/// İleride istenirse:
///  - user_id
///  - language_preference
///  vs. de buraya eklenebilir.
class SecureStorageService {
  /// flutter_secure_storage instance'ı.
  ///
  /// iOS / Android tarafında:
  ///  - Keychain / Keystore kullanır
  ///  - Normal shared_preferences'e göre çok daha güvenlidir.
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Access token'ı yazmak için kullanılacak key.
  static const String _kAccessTokenKey = 'access_token';

  /// Refresh token'ı yazmak için kullanılacak key.
  static const String _kRefreshTokenKey = 'refresh_token';

  /// Access token'ı güvenli storage'a yazar.
  Future<void> writeAccessToken(String token) async {
    await _storage.write(key: _kAccessTokenKey, value: token);
  }

  /// Refresh token'ı güvenli storage'a yazar.
  Future<void> writeRefreshToken(String token) async {
    await _storage.write(key: _kRefreshTokenKey, value: token);
  }

  /// Kayıtlı access token'ı okur.
  ///
  /// Token yoksa null döner.
  Future<String?> readAccessToken() async {
    return _storage.read(key: _kAccessTokenKey);
  }

  /// Kayıtlı refresh token'ı okur.
  ///
  /// Token yoksa null döner.
  Future<String?> readRefreshToken() async {
    return _storage.read(key: _kRefreshTokenKey);
  }

  /// Tüm token'ları temizler.
  ///
  /// Logout senaryosunda kullanılacak:
  ///  - access_token
  ///  - refresh_token
  Future<void> clearTokens() async {
    await _storage.delete(key: _kAccessTokenKey);
    await _storage.delete(key: _kRefreshTokenKey);
  }
}