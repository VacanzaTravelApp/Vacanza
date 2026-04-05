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
  /// True when backend stores a binary profile photo (GET /users/me/profile/photo).
  final bool hasProfilePhoto;
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
    this.hasProfilePhoto = false,
    this.joinDate,
  });

  /// Local fallback when API [displayName] is empty: preferred → full legal name (with optional middle) → first + last.
  static String computeDisplayNameFallback({
    required String firstName,
    String? middleName,
    required String lastName,
    String? preferredName,
  }) {
    if (preferredName != null && preferredName.trim().isNotEmpty) {
      return preferredName.trim();
    }
    final first = firstName.trim();
    final middle = middleName?.trim() ?? '';
    final last = lastName.trim();
    if (middle.isNotEmpty) {
      return '$first $middle $last'.trim();
    }
    return '$first $last'.trim();
  }

  String get displayNameFallback => computeDisplayNameFallback(
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        preferredName: preferredName,
      );

  /// Safe defaults when opening Edit Profile before profile is loaded.
  static UserProfile defaultForDraft({String userId = '', String email = ''}) {
    return UserProfile(
      infoId: '',
      userId: userId,
      email: email,
      firstName: '',
      lastName: '',
      displayName: '',
      hasProfilePhoto: false,
    );
  }

  UserProfile copyWith({
    String? infoId,
    String? userId,
    String? email,
    String? firstName,
    String? middleName,
    String? lastName,
    String? preferredName,
    String? displayName,
    String? country,
    String? birthDate,
    String? gender,
    String? profileImageUrl,
    bool? hasProfilePhoto,
    DateTime? joinDate,
  }) {
    return UserProfile(
      infoId: infoId ?? this.infoId,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      preferredName: preferredName ?? this.preferredName,
      displayName: displayName ?? this.displayName,
      country: country ?? this.country,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      hasProfilePhoto: hasProfilePhoto ?? this.hasProfilePhoto,
      joinDate: joinDate ?? this.joinDate,
    );
  }
}
