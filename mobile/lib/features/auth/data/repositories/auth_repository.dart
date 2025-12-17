import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:mobile/core/network/jwt_interceptor.dart';
import 'package:mobile/features/auth/data/api/auth_api_client.dart';
import 'package:mobile/features/auth/data/firebase/firebase_auth_service.dart';
import 'package:mobile/features/auth/data/models/user_authentication_dto.dart';
import 'package:mobile/features/auth/data/models/user_register_response.dart';
import 'package:mobile/features/auth/data/storage/secure_storage_service.dart';

/// UI/BLoC katmanına tek tipte hata dönmek için kullandığımız exception.
class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => message;
}

/// AuthRepository:
///
/// Sorumluluk:
/// - Firebase register/login
/// - Firebase ID Token alma
/// - Token'ı SecureStorage'a yazma (interceptor ve session restore için)
/// - Backend'e sync çağrıları:
///   - POST /auth/register
///   - GET  /auth/login
///
/// NOT:
/// - Backend "login/register" aslında auth değil, SYNC endpoint.
/// - Email+password backend'e ASLA gitmiyor.
class AuthRepository {
  final FirebaseAuthService _firebaseService;
  final SecureStorageService _storage;

  final Dio _dio;
  late final AuthApiClient _apiClient;

  AuthRepository({
    FirebaseAuthService? firebaseService,
    SecureStorageService? storage,
    Dio? dio,
  })  : _firebaseService = firebaseService ?? FirebaseAuthService(),
        _storage = storage ?? SecureStorageService(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'http://165.232.69.83:9002', // Android emulator -> localhost
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            ) {
    // ✅ Interceptor: her request'e SecureStorage'tan token basar.
    // Not: Auth endpointlerinde biz ayrıca header geçiyoruz, sorun değil.
    _dio.interceptors.add(JwtInterceptor(storage: _storage));

    _apiClient = AuthApiClient(dio: _dio);
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================
  /// Logout:
  /// - storage tokenlarını siler
  /// - firebase signOut yapar
  Future<void> logout() async {
    await _storage.clearSession();
    await _firebaseService.signOut();
  }

  // ==========================================================
  // REGISTER FLOW (Firebase + backend register sync)
  // ==========================================================
  /// Akış:
  /// 1) Firebase createUserWithEmailAndPassword
  /// 2) Firebase ID Token al (FIREBASE_ID_TOKEN)
  /// 3) SecureStorage'a yaz (session restore + interceptor için)
  /// 4) POST /auth/register ile backend'e isimleri sync et
  Future<UserRegisterResponse> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    String? middleName,
    required String lastName,
    String? preferredName,
  }) async {
    try {
      // 1) Firebase register (otomatik login)
      await _firebaseService.register(email, password);

      // 2) Token al
      final firebaseIdToken = await _firebaseService.getIdToken();

      // 3) Token'ı cihazda sakla (session restore için)
      await _storage.writeAccessToken(firebaseIdToken);

      // 4) Backend register sync
      final res = await _apiClient.registerSync(
        firebaseIdToken: firebaseIdToken,
        body: {
          'firstName': firstName,
          'middleName': middleName,
          'lastName': lastName,
          'preferredName': preferredName,
        },
      );

      // Backend "success=false" döndürebilir → bunu failure sayalım.
      if (!res.success) {
        throw AuthFailure(res.message.isNotEmpty
            ? res.message
            : 'Register sync başarısız.');
      }

      return res;
    } on fb.FirebaseAuthException catch (e) {
      // Firebase tarafı hatalar
      switch (e.code) {
        case 'email-already-in-use':
          throw const AuthFailure('Bu email adresi zaten kayıtlı.');
        case 'invalid-email':
          throw const AuthFailure('Geçersiz email adresi.');
        case 'weak-password':
          throw const AuthFailure('Şifre çok zayıf.');
        default:
          throw AuthFailure('Firebase register hatası: ${e.code}');
      }
    } on DioException catch (e) {
      // Backend tarafı hatalar (400/401/500 vs)
      final status = e.response?.statusCode;
      final data = e.response?.data;

      // Backend message alanı döndürüyorsa yakala
      if (data is Map && data['message'] is String) {
        throw AuthFailure(data['message'] as String);
      }

      throw AuthFailure(
        status == null
            ? 'Register sırasında sunucuya ulaşılamadı.'
            : 'Register sırasında sunucu hatası: HTTP $status',
      );
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure('Register sırasında beklenmeyen hata oluştu.');
    }
  }

  // ==========================================================
  // LOGIN FLOW (Firebase + backend login sync)
  // ==========================================================
  /// Akış:
  /// 1) Firebase signInWithEmailAndPassword
  /// 2) Token al
  /// 3) SecureStorage'a yaz
  /// 4) GET /auth/login ile backend'den "me" benzeri data al
  ///
  /// Return:
  /// - UserAuthenticationDTO (backend user bilgisi)
  Future<UserAuthenticationDTO> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // 1) Firebase login
      await _firebaseService.login(email, password);

      // 2) Token al
      final firebaseIdToken = await _firebaseService.getIdToken();

      // 3) Storage'a yaz
      await _storage.writeAccessToken(firebaseIdToken);

      // 4) Backend login sync
      final auth = await _apiClient.loginSync(firebaseIdToken: firebaseIdToken);

      if (auth.userId.isEmpty) {
        throw const AuthFailure('Backend authentication başarısız.');
      }
      return auth;
    } on fb.FirebaseAuthException catch (e) {
      final code = e.code.toLowerCase();
      switch (code) {
        case 'invalid-credential':
        case 'invalid-login-credentials':
          throw const AuthFailure('Email veya şifre hatalı.');
        case 'invalid-email':
          throw const AuthFailure('Geçersiz email formatı.');
        case 'too-many-requests':
          throw const AuthFailure('Çok fazla deneme. Sonra tekrar dene.');
        default:
          throw const AuthFailure('Giriş yapılamadı. Bilgileri kontrol et.');
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      if (data is Map && data['message'] is String) {
        throw AuthFailure(data['message'] as String);
      }

      // Rehbere göre 401 token invalid => logout
      if (status == 401) {
        throw const AuthFailure('Session expired. Please login again.');
      }

      throw AuthFailure(
        status == null
            ? 'Login sırasında sunucuya ulaşılamadı.'
            : 'Login sırasında sunucu hatası: HTTP $status',
      );
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure('Login sırasında beklenmeyen hata oluştu.');
    }
  }

  // ==========================================================
  // SESSION RESTORE (app açılış)
  // ==========================================================
  /// App açılışında:
  /// - Firebase currentUser varsa token alır
  /// - Backend GET /auth/login atar
  /// - 200 ise "authenticated"
  /// - 401 ise session yok
  Future<UserAuthenticationDTO> restoreSession() async {
    try {
      final currentUser = _firebaseService.getCurrentUser();
      if (currentUser == null) {
        throw const AuthFailure('No Firebase session.');
      }

      // Token al (gerekirse yenileyebilirsin: getIdToken(true) istersen service'e eklenir)
      final firebaseIdToken = await _firebaseService.getIdToken();

      // Storage güncelle (interceptor için)
      await _storage.writeAccessToken(firebaseIdToken);

      // Backend check
      final auth = await _apiClient.loginSync(firebaseIdToken: firebaseIdToken);
      if (!auth.authenticated) {
        throw const AuthFailure('Session invalid.');
      }

      return auth;
    } on AuthFailure {
      rethrow;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401) {
        throw const AuthFailure('Session expired.');
      }
      throw const AuthFailure('Session restore sırasında sunucu hatası oluştu.');
    } catch (_) {
      throw const AuthFailure('Session restore sırasında hata oluştu.');
    }
  }
}