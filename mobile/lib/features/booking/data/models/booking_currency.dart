/// Supported ISO-style codes for hotel + flight search (TASK-9).
abstract final class BookingCurrencies {
  BookingCurrencies._();

  static const String defaultCode = 'USD';

  static const List<String> codes = [
    'USD',
    'EUR',
    'GBP',
    'TRY',
    'JPY',
    'CHF',
    'AUD',
    'CAD',
  ];

  static String normalize(String? raw) {
    final code = (raw ?? defaultCode).trim().toUpperCase();
    return codes.contains(code) ? code : defaultCode;
  }
}
