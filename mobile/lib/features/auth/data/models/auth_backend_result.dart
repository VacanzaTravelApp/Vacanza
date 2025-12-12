/// Backend'in auth endpointlerinden dönecek standart sonuç modeli.
///
/// Backend JWT üretmiyor senaryosu:
/// - Backend sadece "authenticated" boolean + "user" datası döner.
/// - Token üretimi / session yönetimi tamamen Firebase ID Token üzerinden yürür.
///   (Yani mobil taraf her request'te Firebase ID Token'ı Bearer olarak taşır.)
///
/// Örnek backend response:
/// {
///   "authenticated": true,
///   "user": {
///     "id": "...",
///     "email": "...",
///     "firstName": "...",
///     "lastName": "...",
///     "preferredNames": ["..."]
///   }
/// }
class AuthBackendResult {
  final bool authenticated;

  /// Backend'in döndüğü user datasını şimdilik Map olarak taşıyoruz.
  /// Backend DTO netleşince bunu UserModel'a çevirebilirsin.
  final Map<String, dynamic> user;

  const AuthBackendResult({
    required this.authenticated,
    required this.user,
  });

  /// JSON -> Model
  factory AuthBackendResult.fromJson(Map<String, dynamic> json) {
    return AuthBackendResult(
      authenticated: (json['authenticated'] as bool?) ?? false,
      user: (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  /// Backend henüz hazır değilken, uygulamanın "auth oldu" akışını test etmek için
  /// üretilecek sahte sonuç.
  ///
  /// Bu sayede:
  /// - Login/Register sonrası MapScreen'e geçiş
  /// - AuthGate'in token var/yok kontrolü
  /// - Interceptor'ın header eklemesi
  /// gibi akışlar backend olmadan da test edilir.
  factory AuthBackendResult.mock({
    required String email,
    required String firebaseUid,
    String? firstName,
    String? middleName,
    String? lastName,
    List<String>? preferredNames,
  }) {
    return AuthBackendResult(
      authenticated: true,
      user: {
        'firebaseUid': firebaseUid,
        'email': email,
        'firstName': firstName ?? 'Mock',
        'middleName': middleName ?? '',
        'lastName': lastName ?? 'User',
        'preferredNames': preferredNames ?? const [],
      },
    );
  }
}