import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

/// UI katmanına dönecek hata tipi
class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  final fb.FirebaseAuth _firebaseAuth;
  final Dio _dio;

  AuthRepository({
    fb.FirebaseAuth? firebaseAuth,
    Dio? dio,
  })  : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'http://10.0.2.2:8080', // TODO: gerçek backend URL
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  /// VACANZA-81: Firebase register + backend register
  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    String? middleName,
    required String lastName,
    required List<String> preferredNames,
  }) async {
    try {
      // ------------------------------------------
      // 1) Firebase tarafında kullanıcı oluştur
      // ------------------------------------------
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        throw const AuthFailure('Kullanıcı oluşturulamadı.');
      }

      // UID + Token al
      final firebaseUid = user.uid;
      final idToken = await user.getIdToken();

      // ------------------------------------------
      // 2) Backend e POST /auth/register (ŞİMDİLİK COMMENT)
      // ------------------------------------------

      /*
      final response = await _dio.post(
        '/auth/register',
        data: {
          'firebaseUid': firebaseUid,
          'firebaseIdToken': idToken,
          'email': email,
          'firstName': firstName,
          'middleName': middleName,
          'lastName': lastName,
          'preferredNames': preferredNames,
        },
      );

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw AuthFailure(
            'Sunucudan beklenmeyen cevap geldi (${response.statusCode})');
      }
      */

      // Backend henüz hazır olmadığı için şimdilik direkt success dönüyoruz
      return;
    }

    // ---------------------------
    // Firebase hata yakalama
    // ---------------------------
    on fb.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw const AuthFailure('Bu email adresi zaten kayıtlı.');
        case 'invalid-email':
          throw const AuthFailure('Geçersiz email adresi.');
        case 'weak-password':
          throw const AuthFailure('Şifre çok zayıf.');
        default:
          throw AuthFailure('Firebase hatası: ${e.code}');
      }
    }

    // ---------------------------
    // Dio hata yakalama
    // (Şimdilik backend yok ama future-proof dursun)
    // ---------------------------
    on DioException catch (e) {
      final status = e.response?.statusCode;

      if (status == 409) {
        throw const AuthFailure('Bu email adresi sistemde zaten kayıtlı.');
      }

      throw AuthFailure(
        e.response?.data['message'] ??
            'Sunucu hatası oluştu. Backend hazır olmayabilir.',
      );
    }

    catch (_) {
      throw const AuthFailure('Beklenmeyen bir hata oluştu.');
    }
  }
}