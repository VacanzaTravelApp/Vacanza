import '../models/user_profile.dart';

class UserProfileDto {
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
  final String? joinDateIso;

  const UserProfileDto({
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
    this.joinDateIso,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      infoId: (json['infoId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      middleName: json['middleName']?.toString(),
      lastName: (json['lastName'] ?? '').toString(),
      preferredName: json['preferredName']?.toString(),
      displayName: (json['displayName'] ?? '').toString(),
      country: json['country']?.toString(),
      birthDate: json['birthDate']?.toString(),
      gender: json['gender']?.toString(),
      profileImageUrl: json['profileImageUrl']?.toString(),
      joinDateIso: json['joinDate']?.toString(),
    );
  }

  UserProfile toDomain() {
    DateTime? joinDate;
    if (joinDateIso != null && joinDateIso!.isNotEmpty) {
      joinDate = DateTime.tryParse(joinDateIso!);
    }
    return UserProfile(
      infoId: infoId,
      userId: userId,
      email: email,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      preferredName: preferredName,
      displayName: displayName,
      country: country,
      birthDate: birthDate,
      gender: gender,
      profileImageUrl: profileImageUrl,
      joinDate: joinDate,
    );
  }

  static Map<String, dynamic> toPartialJson({
    String? firstName,
    String? middleName,
    String? lastName,
    String? preferredName,
    String? country,
    String? birthDate,
    String? gender,
    String? profileImageUrl,
  }) {
    final map = <String, dynamic>{};
    if (firstName != null) map['firstName'] = firstName;
    if (middleName != null) map['middleName'] = middleName;
    if (lastName != null) map['lastName'] = lastName;
    if (preferredName != null) map['preferredName'] = preferredName;
    if (country != null) map['country'] = country;
    if (birthDate != null) map['birthDate'] = birthDate;
    if (gender != null) map['gender'] = gender;
    if (profileImageUrl != null) map['profileImageUrl'] = profileImageUrl;
    return map;
  }
}
