import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Auth ile ilgili token'ların (access ve refresh) güvenli şekilde
/// cihazda saklanmasını yöneten servis.
///
/// Şu an sadece:
///  - access_token
///  - refresh_token
///
/// için helper metodlar var.
/// İleride istenirse başka anahtarlar da eklenebilir.
class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _kAccessTokenKey = 'access_token';
  static const String _kRefreshTokenKey = 'refresh_token';

  /// Access token'ı yazar.
  Future<void> writeAccessToken(String token) async {
    await _storage.write(key: _kAccessTokenKey, value: token);
  }

  /// Refresh token'ı yazar.
  Future<void> writeRefreshToken(String token) async {
    await _storage.write(key: _kRefreshTokenKey, value: token);
  }

  /// Kayıtlı access token'ı okur (yoksa null).
  Future<String?> readAccessToken() async {
    return _storage.read(key: _kAccessTokenKey);
  }

  /// Kayıtlı refresh token'ı okur (yoksa null).
  Future<String?> readRefreshToken() async {
    return _storage.read(key: _kRefreshTokenKey);
  }

  /// Hem access hem refresh token'ı temizler.
  ///
  /// Logout akışında çağrılacaktır.
  Future<void> clearTokens() async {
    await _storage.delete(key: _kAccessTokenKey);
    await _storage.delete(key: _kRefreshTokenKey);
  }
}