import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Firebase Authentication ile ilgili TÜM işlemleri yöneten servis.
///
/// Amaç:
///  - Firebase SDK kullanımını tek yerde toplamak
///  - Repository'nin daha okunaklı ve test edilebilir olması
///
/// NOT:
///  - Firebase'de register başarılı olursa kullanıcı otomatik olarak login olur.
///    Yani register sonrasında currentUser dolu olur.
class FirebaseAuthService {
  /// Uygulama genelinde kullanacağımız FirebaseAuth instance'ı.
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  /// Kullanıcıyı email + şifre ile Firebase üzerinden login eder.
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
  ///  - aynı anda otomatik sign-in olur (currentUser dolar)
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

  /// Firebase tarafındaki oturumu kapatır.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Şu an login olan kullanıcıyı döner.
  fb.User? getCurrentUser() => _auth.currentUser;

  /// Şu an login olan kullanıcının Firebase ID Token'ını döner.
  ///
  /// Backend token doğrulama için bu ID token'ı kullanır.
  /// DİKKAT:
  /// bazı SDK sürümlerinde getIdToken() String? gibi davranabiliyor;
  /// bu yüzden null check ile sağlamlaştırıyoruz.
  Future<String> getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('ID token alınamadı: currentUser null.');
    }

    final token = await user.getIdToken(); // bazen String? gibi davranabiliyor
    if (token == null) {
      throw Exception('ID token alınamadı: Firebase null token döndürdü.');
    }

    return token;
  }
}