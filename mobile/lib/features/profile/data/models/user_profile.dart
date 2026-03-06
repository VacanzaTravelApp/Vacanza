/// Domain model for user profile (GET /users/me/profile).
class UserProfile {
  final String infoId;
  final String userId;
  final String email;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? preferredName;
  final String displayName;
  final String? country;
  final String? birthDate;
  final String? gender;
  final String? profileImageUrl;
  final DateTime? joinDate;

  const UserProfile({
    required this.infoId,
    required this.userId,
    required this.email,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.preferredName,
    required this.displayName,
    this.country,
    this.birthDate,
    this.gender,
    this.profileImageUrl,
    this.joinDate,
  });

  String get displayNameFallback =>
      (preferredName != null && preferredName!.trim().isNotEmpty)
          ? preferredName!
          : '$firstName ${lastName.trim()}'.trim();
}
