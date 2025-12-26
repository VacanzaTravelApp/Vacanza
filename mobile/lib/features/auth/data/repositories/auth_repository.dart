import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

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
/// - Firebase register/login
/// - Firebase ID Token alma
/// - Token'ı SecureStorage'a yazma
/// - Backend'e sync çağrıları:
///   - POST /auth/register
///   - GET  /auth/login
class AuthRepository {
  final FirebaseAuthService _firebaseService;
  final SecureStorageService _storage;

  /// Dio DI (tek ortak dio)
  final Dio _dio;

  late final AuthApiClient _apiClient;

  AuthRepository({
    FirebaseAuthService? firebaseService,
    required SecureStorageService storage,
    required Dio dio,
  })  : _firebaseService = firebaseService ?? FirebaseAuthService(),
        _storage = storage,
        _dio = dio {
    // IMPORTANT:
    // JwtInterceptor ve baseUrl app_dio.dart içinde zaten eklendi.
    _apiClient = AuthApiClient(dio: _dio);
  }

  /// Logout:
  /// - storage tokenlarını siler
  /// - firebase signOut yapar
  Future<void> logout() async {
    await _storage.clearSession();
    await _firebaseService.signOut();
  }

  /// Register akışı:
  /// 1) Firebase createUserWithEmailAndPassword
  /// 2) Firebase ID Token al
  /// 3) SecureStorage'a yaz
  /// 4) POST /auth/register (sync)
  Future<UserRegisterResponse> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    String? middleName,
    required String lastName,
    String? preferredName,
  }) async {
    try {
      await _firebaseService.register(email, password);

      final firebaseIdToken = await _firebaseService.getIdToken();

      await _storage.writeAccessToken(firebaseIdToken);

      final res = await _apiClient.registerSync(
        firebaseIdToken: firebaseIdToken,
        body: {
          'firstName': firstName,
          'middleName': middleName,
          'lastName': lastName,
          'preferredName': preferredName,
        },
      );

      if (!res.success) {
        throw AuthFailure(
          res.message.isNotEmpty ? res.message : 'Register sync başarısız.',
        );
      }

      return res;
    } on fb.FirebaseAuthException catch (e) {
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
      final status = e.response?.statusCode;
      final data = e.response?.data;

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

  /// Login akışı:
  /// 1) Firebase signInWithEmailAndPassword
  /// 2) Token al
  /// 3) SecureStorage'a yaz
  /// 4) GET /auth/login (sync)
  Future<UserAuthenticationDTO> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseService.login(email, password);

      final firebaseIdToken = await _firebaseService.getIdToken();
      await _storage.writeAccessToken(firebaseIdToken);

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

  /// Session restore:
  /// - Firebase currentUser varsa token alır
  /// - Backend GET /auth/login atar
  Future<UserAuthenticationDTO> restoreSession() async {
    try {
      final currentUser = _firebaseService.getCurrentUser();
      if (currentUser == null) {
        throw const AuthFailure('No Firebase session.');
      }

      final firebaseIdToken = await _firebaseService.getIdToken();
      await _storage.writeAccessToken(firebaseIdToken);

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