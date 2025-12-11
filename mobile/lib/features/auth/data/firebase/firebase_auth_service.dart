import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Firebase Authentication ile ilgili TÜM işlemleri yöneten servis.
///
/// Amaç:
///  - Firebase SDK kullanımını tek yerde toplamak
///  - Repository’nin daha okunaklı ve test edilebilir olması
///  - Login / register / idToken alma işlerini soyutlamak
///
/// NOT:
///  - Firebase'de register başarılı olursa kullanıcı otomatik olarak login olur.
///    Yani register sonrasında currentUser dolu olur.
class FirebaseAuthService {
  /// Uygulama genelinde kullanacağımız FirebaseAuth instance'ı.
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  /// Kullanıcıyı email + şifre ile Firebase üzerinden login eder.
  /// Başarılı olursa [fb.User] döner.
  Future<fb.User> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user == null) {
      throw Exception('Firebase login başarısız: user null geldi.');
    }

    return user;
  }

  /// Yeni bir kullanıcı oluşturur.
  ///
  /// Firebase tarafında:
  ///  - kullanıcı create edilir
  ///  - aynı anda otomatik olarak sign-in olur (currentUser dolar)
  Future<fb.User> register(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = cred.user;
    if (user == null) {
      throw Exception('Firebase register başarısız: user null geldi.');
    }

    return user;
  }

  /// Şu an login olan kullanıcıyı döner.
  fb.User? getCurrentUser() => _auth.currentUser;

  /// Şu an login olan kullanıcının Firebase ID Token'ını döner.
  ///
  /// Backend token doğrulama için bu ID token'ı kullanır.
  Future<String> getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('ID token alınamadı: currentUser null.');
    }

    return await user.getIdToken();
  }
}