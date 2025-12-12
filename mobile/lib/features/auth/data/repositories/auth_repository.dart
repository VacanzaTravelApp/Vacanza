import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:mobile/core/network/jwt_interceptor.dart';
import 'package:mobile/features/auth/data/api/auth_api_client.dart';
import 'package:mobile/features/auth/data/firebase/firebase_auth_service.dart';
import 'package:mobile/features/auth/data/models/auth_backend_result.dart';
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
///  - FirebaseAuthService: gerçek Firebase login/register
///  - AuthApiClient: backend /auth/register & /auth/login (opsiyonel, feature flag ile)
///  - SecureStorageService: token saklama
///
/// Bu repository hem Login hem Register için ortak "entry point".
///
/// ÖNEMLİ STRATEJİ (senin istediğin):
///  - Backend token üretmiyor.
///  - Biz "session" gibi davranması için cihazda Firebase ID Token saklıyoruz.
///  - Her request'te Bearer olarak bunu gönderiyoruz.
///  - Backend sadece "authenticated + user" gibi bilgi döndürüyor.
///
/// Backend henüz yokken:
///  - HTTP çağrısı yapmadan "mock" AuthBackendResult dönüyoruz.
///  - Ama yine de token storage’a yazıyoruz → AuthGate çalışıyor.
class AuthRepository {
  final FirebaseAuthService _firebaseService;
  final SecureStorageService _storage;

  /// Tek Dio instance.
  /// - Interceptor burada takılı
  /// - ApiClient de aynı Dio'yu kullanıyor
  final Dio _dio;

  late final AuthApiClient _apiClient;

  /// Backend entegrasyonu aç/kapa bayrağı.
  /// Backend hazır olduğunda true yapacaksın.
  final bool _backendEnabled;

  AuthRepository({
    FirebaseAuthService? firebaseService,
    SecureStorageService? storage,
    Dio? dio,
    bool backendEnabled = false,
  })  : _firebaseService = firebaseService ?? FirebaseAuthService(),
        _storage = storage ?? SecureStorageService(),
        _backendEnabled = backendEnabled,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'http://10.0.2.2:8080', // TODO: prod URL
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            ) {
    // 1) JwtInterceptor'ı TEK dio instance'ına ekliyoruz.
    //    Not: burada okunan access_token artık "Firebase ID Token" olacak.
    _dio.interceptors.add(JwtInterceptor(storage: _storage));

    // 2) AuthApiClient aynı dio ile oluşturulur (interceptor/ayarlar ortak kalsın)
    _apiClient = AuthApiClient(dio: _dio);
  }

  // ==========================================================
  // LOGOUT FLOW
  // ==========================================================
  /// Logout:
  /// - SecureStorage tokenlarını siler
  /// - Firebase session'ı kapatır
  ///
  /// UI (MapScreen vs) bunu çağırıp Login'e pushReplacement atar.
  Future<void> logout() async {
    await _storage.clearSession();
    await _firebaseService.signOut();
  }

  // ==========================================================
  // REGISTER FLOW
  // ==========================================================
  /// Register akışı (Firebase + opsiyonel backend):
  ///
  /// 1) Firebase register (otomatik login olur)
  /// 2) Firebase ID Token alınır
  /// 3) Token SecureStorage'a yazılır  ✅ (AuthGate / interceptor için)
  /// 4) Backend ENABLED ise:
  ///    - POST /auth/register (Bearer token + user body)
  ///    - backend authenticated + user döner
  /// 5) Backend DISABLED ise:
  ///    - mock AuthBackendResult döner
  Future<AuthBackendResult> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    String? middleName,
    required String lastName,
    required List<String> preferredNames,
  }) async {
    try {
      // 1) Firebase: create user (auto-login)
      final user = await _firebaseService.register(email, password);

      // 2) Firebase ID Token: backend verification / session
      final firebaseIdToken = await _firebaseService.getIdToken();

      // 3) Storage: app’in authenticated sayması için tokenı yazıyoruz.
      //    Backend JWT üretmiyorsa bile bu token "access_token" key'inde saklanacak.
      await _storage.writeAccessToken(firebaseIdToken);

      // 4) Backend implementasyonu geldiğinde:
      //    - _backendEnabled = true yapacaksın
      //    - Aşağıdaki HTTP çağrısı gerçek backend'e gidecek
      if (_backendEnabled) {
        final result = await _apiClient.register(
          firebaseIdToken: firebaseIdToken,
          body: {
            // Backend'e giden JSON: user profil bilgileri
            'email': email,
            'firstName': firstName,
            'middleName': middleName,
            'lastName': lastName,
            'preferredNames': preferredNames,
          },
        );

        // Backend'in authenticated=false döndürmesi durumunda:
        // UI bunu failure sayabilir (istersen burada kontrol ekleriz).
        return result;
      }

      // 5) Backend yokken mock:
      return AuthBackendResult.mock(
        email: email,
        firebaseUid: user.uid,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        preferredNames: preferredNames,
      );
    } on fb.FirebaseAuthException catch (e) {
      // Firebase register hatalarını kullanıcı dostu mesajlara mapliyoruz.
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
      // Backend enabled iken buraya düşebilir.
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        throw AuthFailure(data['message'] as String);
      }
      throw const AuthFailure('Register sırasında sunucu hatası oluştu.');
    } catch (_) {
      throw const AuthFailure('Register sırasında beklenmeyen hata oluştu.');
    }
  }

  // ==========================================================
  // LOGIN FLOW
  // ==========================================================
  /// Login akışı (Firebase + opsiyonel backend):
  ///
  /// 1) Firebase login
  /// 2) Firebase ID Token alınır
  /// 3) Token SecureStorage'a yazılır ✅
  /// 4) Backend ENABLED ise:
  ///    - POST /auth/login (Bearer token + opsiyonel body)
  ///    - backend authenticated + user döner
  /// 5) Backend DISABLED ise:
  ///    - mock AuthBackendResult döner
  Future<AuthBackendResult> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // 1) Firebase login
      final user = await _firebaseService.login(email, password);

      // 2) Firebase ID Token
      final firebaseIdToken = await _firebaseService.getIdToken();

      // 3) Storage
      await _storage.writeAccessToken(firebaseIdToken);

      // 4) Backend implementasyonu geldiğinde:
      //    - _backendEnabled = true
      //    - /auth/login gerçek çağrılır
      if (_backendEnabled) {
        final result = await _apiClient.login(
          firebaseIdToken: firebaseIdToken,
          body: const {}, // backend isterse burayı genişletiriz
        );
        return result;
      }

      // 5) Backend yokken mock
      return AuthBackendResult.mock(
        email: email,
        firebaseUid: user.uid,
      );
    } on fb.FirebaseAuthException catch (e) {
      // Firebase login error code’ları SDK sürümüne göre değişebiliyor.
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
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        throw AuthFailure(data['message'] as String);
      }
      throw const AuthFailure('Login sırasında sunucu hatası oluştu.');
    } catch (_) {
      throw const AuthFailure('Login sırasında beklenmeyen hata oluştu.');
    }
  }
}