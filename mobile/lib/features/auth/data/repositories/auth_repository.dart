import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:mobile/features/auth/data/firebase/firebase_auth_service.dart';
import 'package:mobile/features/auth/data/api/auth_api_client.dart';
import 'package:mobile/features/auth/data/storage/secure_storage_service.dart';

/// UI/BLoC katmanına döneceğimiz anlamlı hata tipi.
/// Firebase ve backend hatalarını tek tipte temsil ediyoruz.
class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => message;
}

/// AuthRepository:
///  - FirebaseAuthService ile Firebase login/register
///  - AuthApiClient ile backend /auth çağrıları (şu an COMMENT)
///  - SecureStorageService ile access/refresh token saklama
///
/// Şu an "fallback" modda çalışıyor:
///  - Firebase ile login/register gerçekten yapılıyor
///  - Backend çağrı kodları hazır ama COMMENT durumunda
///  - Buna rağmen dummy tokenlar yazarak app'in geri kalanı test edilebiliyor
class AuthRepository {
  final FirebaseAuthService _firebaseService;
  final AuthApiClient _apiClient;
  final SecureStorageService _storage;

  AuthRepository({
    FirebaseAuthService? firebaseService,
    AuthApiClient? apiClient,
    SecureStorageService? storage,
  })  : _firebaseService = firebaseService ?? FirebaseAuthService(),
        _apiClient = apiClient ?? AuthApiClient(),
        _storage = storage ?? SecureStorageService();

  // =======================================================================
  // REGISTER FLOW (Firebase Register + ileride Backend Register + Token Save)
  // =======================================================================
  ///
  /// Akış:
  ///  1) Firebase'de kullanıcı oluştur (otomatik login olur)
  ///  2) Firebase ID token al
  ///  3) (İLERİDE) backend /auth/register endpoint'ine POST at
  ///  4) Access/refresh tokenları secure storage'a yaz
  ///
  /// ŞU AN:
  ///  - Backend çağrısı COMMENT'li
  ///  - dummy access/refresh token yazıyoruz (backend gelene kadar)
  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    String? middleName,
    required String lastName,
    required List<String> preferredNames,
  }) async {
    try {
      // 1) Firebase'de kullanıcı oluştur (ve otomatik login olur)
      final user = await _firebaseService.register(email, password);

      // 2) Kullanıcının Firebase ID Token'ını al
      final idToken = await _firebaseService.getIdToken();

      // 3) BACKEND REGISTER (backend hazır olduğunda aktif edilecek)
      // ------------------------------------------------------------------
      // final response = await _apiClient.register(
      //   body: {
      //     'firebaseUid': user.uid,
      //     'firebaseIdToken': idToken,
      //     'email': email,
      //     'firstName': firstName,
      //     'middleName': middleName,
      //     'lastName': lastName,
      //     'preferredNames': preferredNames,
      //   },
      // );
      //
      // final accessToken = response['access_token'] as String?;
      // final refreshToken = response['refresh_token'] as String?;
      //
      // if (accessToken == null || refreshToken == null) {
      //   throw const AuthFailure(
      //       'Sunucu yanıtında access/refresh token bulunamadı.');
      // }
      //
      // await _storage.writeAccessToken(accessToken);
      // await _storage.writeRefreshToken(refreshToken);
      // ------------------------------------------------------------------

      // 4) BACKEND YOKKEN: dummy token yazarak akışı bozma
      await _storage.writeAccessToken('dev-register-access-${user.uid}');
      await _storage.writeRefreshToken('dev-register-refresh-${user.uid}');
    }

    // Firebase kaynaklı hatalar
    on fb.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw const AuthFailure('Bu email adresi zaten kayıtlı.');
        case 'invalid-email':
          throw const AuthFailure('Geçersiz email formatı.');
        case 'weak-password':
          throw const AuthFailure('Şifre çok zayıf.');
        default:
          throw AuthFailure('Firebase register hatası: ${e.code}');
      }
    }

    // Backend hataları (şu an aktif olmasa da future-proof)
    on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      if (status == 409) {
        throw const AuthFailure('Bu email ile zaten kayıtlı bir kullanıcı var.');
      }

      if (data is Map && data['message'] is String) {
        throw AuthFailure(data['message'] as String);
      }

      throw const AuthFailure(
          'Register sırasında sunucu hatası oluştu. Lütfen tekrar deneyin.');
    }

    // Diğer beklenmeyen hatalar
    catch (_) {
      throw const AuthFailure(
          'Register işlemi sırasında beklenmeyen bir hata oluştu.');
    }
  }

  // =======================================================================
  // LOGIN FLOW (Firebase Login + ileride Backend Login + Token Save)
  // =======================================================================
  ///
  /// Akış:
  ///  1) Firebase login (email + password)
  ///  2) Firebase ID token al
  ///  3) (İLERİDE) backend /auth/login'e gönder
  ///  4) Access/refresh tokenları secure storage'a yaz
  ///
  /// ŞU AN:
  ///  - Backend login çağrısı COMMENT'li
  ///  - dummy token yazarak app'i çalışır durumda tutuyoruz
  Future<void> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // 1) Firebase login
      final user = await _firebaseService.login(email, password);

      // 2) Firebase ID token al
      final idToken = await _firebaseService.getIdToken();

      // 3) BACKEND LOGIN (backend hazır olduğunda aktif edilecek)
      // ------------------------------------------------------------------
      // final response = await _apiClient.login(
      //   firebaseUid: user.uid,
      //   firebaseIdToken: idToken,
      // );
      //
      // final accessToken = response['access_token'] as String?;
      // final refreshToken = response['refresh_token'] as String?;
      //
      // if (accessToken == null || refreshToken == null) {
      //   throw const AuthFailure(
      //       'Sunucu yanıtında access/refresh token bulunamadı.');
      // }
      //
      // await _storage.writeAccessToken(accessToken);
      // await _storage.writeRefreshToken(refreshToken);
      // ------------------------------------------------------------------

      // 4) BACKEND YOKKEN: dummy token yazarak devam
      await _storage.writeAccessToken('dev-login-access-${user.uid}');
      await _storage.writeRefreshToken('dev-login-refresh-${user.uid}');
    }

    // Firebase login hataları
    on fb.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw const AuthFailure('Bu email ile kayıtlı kullanıcı bulunamadı.');
        case 'wrong-password':
          throw const AuthFailure('Email veya şifre hatalı.');
        case 'invalid-email':
          throw const AuthFailure('Geçersiz email formatı.');
        case 'too-many-requests':
          throw const AuthFailure(
              'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.');
        default:
          throw AuthFailure('Firebase login hatası: ${e.code}');
      }
    }

    // Backend login hataları (ileriye dönük)
    on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      if (status == 401) {
        throw const AuthFailure('Giriş yetkiniz yok (401).');
      }
      if (status == 403) {
        throw const AuthFailure('Hesabınız henüz doğrulanmamış (403).');
      }

      if (data is Map && data['message'] is String) {
        throw AuthFailure(data['message'] as String);
      }

      throw const AuthFailure(
          'Login sırasında sunucu hatası oluştu. Lütfen tekrar deneyin.');
    }

    catch (_) {
      throw const AuthFailure(
          'Login işlemi sırasında beklenmeyen bir hata oluştu.');
    }
  }
}