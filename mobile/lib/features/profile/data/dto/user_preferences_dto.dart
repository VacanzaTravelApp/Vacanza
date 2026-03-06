import '../models/user_preferences.dart';

class UserPreferencesDto {
  final String preferencesId;
  final String userId;
  final String? travelStyle;
  final List<String> favoriteCategories;
  final String? activityLevel;
  final List<String> cuisinePreferences;
  final String? preferredClimate;
  final String? tripPace;
  final String? accommodationType;
  final String? transportPreference;
  final List<String> dietaryRestrictions;
  final List<String> accessibilityNeeds;
  final List<String> avoidCategories;
  final num? dailyBudget;
  final String? budgetCurrency;
  final List<String> splurgeCategories;
  final String? preferredLanguage;
  final List<String> spokenLanguages;
  final String? createdAtIso;
  final String? updatedAtIso;

  const UserPreferencesDto({
    required this.preferencesId,
    required this.userId,
    this.travelStyle,
    this.favoriteCategories = const [],
    this.activityLevel,
    this.cuisinePreferences = const [],
    this.preferredClimate,
    this.tripPace,
    this.accommodationType,
    this.transportPreference,
    this.dietaryRestrictions = const [],
    this.accessibilityNeeds = const [],
    this.avoidCategories = const [],
    this.dailyBudget,
    this.budgetCurrency,
    this.splurgeCategories = const [],
    this.preferredLanguage,
    this.spokenLanguages = const [],
    this.createdAtIso,
    this.updatedAtIso,
  });

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  factory UserPreferencesDto.fromJson(Map<String, dynamic> json) {
    return UserPreferencesDto(
      preferencesId: (json['preferencesId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      travelStyle: json['travelStyle']?.toString(),
      favoriteCategories: _toStringList(json['favoriteCategories']),
      activityLevel: json['activityLevel']?.toString(),
      cuisinePreferences: _toStringList(json['cuisinePreferences']),
      preferredClimate: json['preferredClimate']?.toString(),
      tripPace: json['tripPace']?.toString(),
      accommodationType: json['accommodationType']?.toString(),
      transportPreference: json['transportPreference']?.toString(),
      dietaryRestrictions: _toStringList(json['dietaryRestrictions']),
      accessibilityNeeds: _toStringList(json['accessibilityNeeds']),
      avoidCategories: _toStringList(json['avoidCategories']),
      dailyBudget: json['dailyBudget'] as num?,
      budgetCurrency: json['budgetCurrency']?.toString(),
      splurgeCategories: _toStringList(json['splurgeCategories']),
      preferredLanguage: json['preferredLanguage']?.toString(),
      spokenLanguages: _toStringList(json['spokenLanguages']),
      createdAtIso: json['createdAt']?.toString(),
      updatedAtIso: json['updatedAt']?.toString(),
    );
  }

  UserPreferences toDomain() {
    DateTime? createdAt;
    DateTime? updatedAt;
    if (createdAtIso != null && createdAtIso!.isNotEmpty) {
      createdAt = DateTime.tryParse(createdAtIso!);
    }
    if (updatedAtIso != null && updatedAtIso!.isNotEmpty) {
      updatedAt = DateTime.tryParse(updatedAtIso!);
    }
    return UserPreferences(
      preferencesId: preferencesId,
      userId: userId,
      travelStyle: travelStyle,
      favoriteCategories: favoriteCategories,
      activityLevel: activityLevel,
      cuisinePreferences: cuisinePreferences,
      preferredClimate: preferredClimate,
      tripPace: tripPace,
      accommodationType: accommodationType,
      transportPreference: transportPreference,
      dietaryRestrictions: dietaryRestrictions,
      accessibilityNeeds: accessibilityNeeds,
      avoidCategories: avoidCategories,
      dailyBudget: dailyBudget,
      budgetCurrency: budgetCurrency,
      splurgeCategories: splurgeCategories,
      preferredLanguage: preferredLanguage,
      spokenLanguages: spokenLanguages,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static Map<String, dynamic> toPartialJson({
    String? travelStyle,
    List<String>? favoriteCategories,
    String? activityLevel,
    List<String>? cuisinePreferences,
    String? preferredClimate,
    String? tripPace,
    String? accommodationType,
    String? transportPreference,
    List<String>? dietaryRestrictions,
    List<String>? accessibilityNeeds,
    List<String>? avoidCategories,
    num? dailyBudget,
    String? budgetCurrency,
    List<String>? splurgeCategories,
    String? preferredLanguage,
    List<String>? spokenLanguages,
  }) {
    final map = <String, dynamic>{};
    if (travelStyle != null) map['travelStyle'] = travelStyle;
    if (favoriteCategories != null) map['favoriteCategories'] = favoriteCategories;
    if (activityLevel != null) map['activityLevel'] = activityLevel;
    if (cuisinePreferences != null) map['cuisinePreferences'] = cuisinePreferences;
    if (preferredClimate != null) map['preferredClimate'] = preferredClimate;
    if (tripPace != null) map['tripPace'] = tripPace;
    if (accommodationType != null) map['accommodationType'] = accommodationType;
    if (transportPreference != null) map['transportPreference'] = transportPreference;
    if (dietaryRestrictions != null) map['dietaryRestrictions'] = dietaryRestrictions;
    if (accessibilityNeeds != null) map['accessibilityNeeds'] = accessibilityNeeds;
    if (avoidCategories != null) map['avoidCategories'] = avoidCategories;
    if (dailyBudget != null) map['dailyBudget'] = dailyBudget;
    if (budgetCurrency != null) map['budgetCurrency'] = budgetCurrency;
    if (splurgeCategories != null) map['splurgeCategories'] = splurgeCategories;
    if (preferredLanguage != null) map['preferredLanguage'] = preferredLanguage;
    if (spokenLanguages != null) map['spokenLanguages'] = spokenLanguages;
    return map;
  }
}
