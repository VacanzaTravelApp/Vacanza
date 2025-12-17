/// POST /auth/register response DTO
///
/// Örnek:
/// {
///   "success": true,
///   "message": "User registered successfully",
///   "userId": "UUID"
/// }
class UserRegisterResponse {
  final bool success;
  final String message;
  final String userId;

  const UserRegisterResponse({
    required this.success,
    required this.message,
    required this.userId,
  });

  factory UserRegisterResponse.fromJson(Map<String, dynamic> json) {
    return UserRegisterResponse(
      success: (json['success'] as bool?) ?? false,
      message: (json['message'] as String?) ?? '',
      userId: (json['userId'] as String?) ?? '',
    );
  }
}