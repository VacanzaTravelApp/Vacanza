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

  /// Safe defaults when opening Edit Preferences before preferences are loaded.
  static UserPreferences defaultForDraft({String userId = ''}) {
    return UserPreferences(
      preferencesId: '',
      userId: userId,
    );
  }

  UserPreferences copyWith({
    String? preferencesId,
    String? userId,
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreferences(
      preferencesId: preferencesId ?? this.preferencesId,
      userId: userId ?? this.userId,
      travelStyle: travelStyle ?? this.travelStyle,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      activityLevel: activityLevel ?? this.activityLevel,
      cuisinePreferences: cuisinePreferences ?? this.cuisinePreferences,
      preferredClimate: preferredClimate ?? this.preferredClimate,
      tripPace: tripPace ?? this.tripPace,
      accommodationType: accommodationType ?? this.accommodationType,
      transportPreference: transportPreference ?? this.transportPreference,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      accessibilityNeeds: accessibilityNeeds ?? this.accessibilityNeeds,
      avoidCategories: avoidCategories ?? this.avoidCategories,
      dailyBudget: dailyBudget ?? this.dailyBudget,
      budgetCurrency: budgetCurrency ?? this.budgetCurrency,
      splurgeCategories: splurgeCategories ?? this.splurgeCategories,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      spokenLanguages: spokenLanguages ?? this.spokenLanguages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
