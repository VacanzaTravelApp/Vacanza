// Option lists and display helpers for user preferences (profile_frontend_guide.md).
// Only options for the 16 editable preference fields are defined here.

// ─── Enums (must match backend entity.enums for PUT /users/me/preferences) ──

const List<String> optionTravelStyle = [
  'RELAXATION', // backend enum (guide said RELAXED)
  'ADVENTURE',
  'LUXURY',
  'BACKPACKER',
  'CULTURAL',
  'NIGHTLIFE',
  'FAMILY',
  'ROMANTIC',
];

const List<String> optionActivityLevel = [
  'LOW',
  'MODERATE',
  'HIGH',
];

const List<String> optionTripPace = [
  'SLOW',
  'MODERATE',
  'FAST',
];

const List<String> optionAccommodationType = [
  'HOTEL',
  'HOSTEL',
  'APARTMENT', // backend enum (guide said AIRBNB)
  'RESORT',
  'BOUTIQUE',
  'ANY',
];

const List<String> optionTransportPreference = [
  'WALKING',
  'PUBLIC_TRANSPORT',
  'CAR_RENTAL', // backend enum (guide said CAR)
  'TAXI',
  'ANY',
];

const List<String> optionPreferredClimate = [
  'TROPICAL',
  'TEMPERATE',
  'COLD',
  'DESERT',
  'ANY',
];

// ─── List options (guide examples + common) ─────────────────────────────────

const List<String> optionFavoriteCategories = [
  'museum',
  'park',
  'cafe',
  'restaurant',
  'beach',
  'market',
  'gallery',
  'temple',
  'nature',
  'bar',
  'shopping',
  'nightclub',
  'landmark',
];

const List<String> optionCuisinePreferences = [
  'turkish',
  'italian',
  'french',
  'japanese',
  'mexican',
  'indian',
  'greek',
  'thai',
  'chinese',
  'american',
];

const List<String> optionDietaryRestrictions = [
  'gluten',
  'peanuts',
  'dairy',
  'shellfish',
  'eggs',
  'soy',
  'tree-nuts',
  'vegetarian',
  'vegan',
  'halal',
  'kosher',
];

const List<String> optionAccessibilityNeeds = [
  'wheelchair',
  'elevator',
  'quiet-spaces',
  'visual-aids',
  'hearing-loop',
];

/// Same as favorite categories; used for avoid and splurge.
const List<String> optionAvoidCategories = optionFavoriteCategories;
const List<String> optionSplurgeCategories = optionFavoriteCategories;

const List<String> optionLanguages = [
  'en',
  'tr',
  'de',
  'fr',
  'es',
  'it',
  'pt',
  'ar',
  'zh',
  'ja',
  'ko',
  'ru',
];

const List<String> optionBudgetCurrency = [
  'EUR',
  'USD',
  'GBP',
  'TRY',
  'JPY',
  'CAD',
  'AUD',
  'CHF',
  'AED',
  'SGD',
];

// ─── Display helper ────────────────────────────────────────────────────────

/// Format a preference value for display (e.g. "RELAXED" → "Relaxed", "tree-nuts" → "Tree nuts").
String formatOptionLabel(String value) {
  if (value.isEmpty) return value;
  final lower = value.toLowerCase().replaceAll('_', ' ');
  return '${lower[0].toUpperCase()}${lower.substring(1)}';
}
