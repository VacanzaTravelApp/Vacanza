/// Domain model for user travel preferences (GET /users/me/preferences).
class UserPreferences {
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserPreferences({
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
    this.createdAt,
    this.updatedAt,
  });
}
