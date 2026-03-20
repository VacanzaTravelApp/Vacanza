// Options for Edit Profile sheet (profile_frontend_guide.md).
// Backend gender enum: MALE, FEMALE, PREFER_NOT_TO_SAY.

const List<String> profileGenderOptions = [
  'MALE',
  'FEMALE',
  'PREFER_NOT_TO_SAY',
];

/// Common country names in English (for search picker).
/// Extend as needed; backend accepts any string.
const List<String> profileCountryOptions = [
  'Turkey',
  'Germany',
  'United States',
  'United Kingdom',
  'France',
  'Italy',
  'Spain',
  'Netherlands',
  'Austria',
  'Switzerland',
  'Belgium',
  'Portugal',
  'Greece',
  'Poland',
  'Sweden',
  'Norway',
  'Denmark',
  'Finland',
  'Ireland',
  'Canada',
  'Australia',
  'Japan',
  'South Korea',
  'China',
  'India',
  'Brazil',
  'Mexico',
  'Argentina',
  'Chile',
  'Colombia',
  'United Arab Emirates',
  'Saudi Arabia',
  'Israel',
  'Egypt',
  'South Africa',
  'Russia',
  'Ukraine',
  'Czech Republic',
  'Romania',
  'Hungary',
  'New Zealand',
  'Singapore',
  'Thailand',
  'Indonesia',
  'Malaysia',
  'Philippines',
  'Vietnam',
];

String formatGenderLabel(String value) {
  switch (value) {
    case 'MALE':
      return 'Male';
    case 'FEMALE':
      return 'Female';
    case 'PREFER_NOT_TO_SAY':
      return 'Prefer not to say';
    default:
      return value;
  }
}
