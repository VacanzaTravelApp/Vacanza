/// GET /auth/login response DTO (backend direkt user dönüyor)
///
/// Örnek:
/// {
///   "userId": "UUID",
///   "firebaseUid": "firebase_uid",
///   "email": "user@mail.com",
///   "role": "USER",
///   "verified": false,
///   "profileCompleted": true
/// }
class UserAuthenticationDTO {
  final String userId;
  final String firebaseUid;
  final String email;
  final String role;
  final bool verified;
  final bool profileCompleted;

  const UserAuthenticationDTO({
    required this.userId,
    required this.firebaseUid,
    required this.email,
    required this.role,
    required this.verified,
    required this.profileCompleted,
  });

  factory UserAuthenticationDTO.fromJson(Map<String, dynamic> json) {
    return UserAuthenticationDTO(
      userId: (json['userId'] as String?) ?? '',
      firebaseUid: (json['firebaseUid'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      role: (json['role'] as String?) ?? '',
      verified: (json['verified'] as bool?) ?? false,
      profileCompleted: (json['profileCompleted'] as bool?) ?? false,
    );
  }

  /// Convenience: 200 geldiyse authenticated sayabiliriz.
  bool get authenticated => userId.isNotEmpty && firebaseUid.isNotEmpty;
}