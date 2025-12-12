import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:mobile/core/network/jwt_interceptor.dart'; // ✅ eklendi
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

  /// ✅ _apiClient artık "late final"
  /// Çünkü constructor body içinde aynı Dio ile kuracağız.
  late final AuthApiClient _apiClient;

  final SecureStorageService _storage;

  /// ✅ TEK dio instance
  /// Interceptor bunun üstüne takılacak ve AuthApiClient de bunu kullanacak.
  final Dio _dio;

  AuthRepository({
    FirebaseAuthService? firebaseService,
    AuthApiClient? apiClient,
    SecureStorageService? storage,
    Dio? dio,
  })  : _firebaseService = firebaseService ?? FirebaseAuthService(),
        _storage = storage ?? SecureStorageService(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'http://10.0.2.2:8080', // TODO: prod URL eklenecek
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            ) {
    // ✅ 1) Interceptor'ı TEK Dio instance'ına ekliyoruz
    _dio.interceptors.add(JwtInterceptor(storage: _storage));

    // ✅ 2) AuthApiClient'i aynı Dio ile kuruyoruz
    //    (Dışarıdan apiClient inject edilirse onu kullanır.)
    _apiClient = apiClient ?? AuthApiClient(dio: _dio);
  }

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
    // ----------------- Firebase login hataları -----------------
    on fb.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-credential':
        case 'invalid-login-credentials':
          throw const AuthFailure('Email veya şifre hatalı.');

        case 'user-not-found':
          throw const AuthFailure('Bu email ile kayıtlı kullanıcı bulunamadı.');

        case 'wrong-password':
          throw const AuthFailure('Email veya şifre hatalı.');

        case 'invalid-email':
          throw const AuthFailure('Geçersiz email formatı.');

        case 'too-many-requests':
          throw const AuthFailure(
            'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.',
          );

        default:
          throw const AuthFailure(
            'Giriş yapılamadı. Lütfen email ve şifrenizi kontrol edin.',
          );
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

      /// Kullanıcı logout işlemi.
      /// - SecureStorage tokenları temizlenir
      /// - Firebase session kapatılır
      Future<void> logout() async {
        await _storage.clearSession();
        await _firebaseService.signOut();
      }

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


    on fb.FirebaseAuthException catch (e) {
      final code = e.code.toLowerCase();

      switch (code) {
        case 'invalid-credential':
        case 'invalid-login-credentials':
          throw const AuthFailure('Email or password is incorrect.');

        case 'user-not-found':
          throw const AuthFailure('No user found with this email.');

        case 'wrong-password':
          throw const AuthFailure('Email or password is incorrect.');

        case 'invalid-email':
          throw const AuthFailure('Invalid email format.');

        case 'user-disabled':
          throw const AuthFailure('This user account has been disabled.');

        case 'too-many-requests':
          throw const AuthFailure(
            'Too many login attempts. Please try again later.',
          );

        default:
          throw const AuthFailure(
            'Login failed. Please check your email and password.',
          );
      }
    }

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