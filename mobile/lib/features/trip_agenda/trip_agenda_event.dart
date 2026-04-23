import 'package:flutter/material.dart';

/// Local-only trip calendar event (same fields as web CalendarModal).
class TripAgendaEvent {
  const TripAgendaEvent({
    required this.title,
    required this.category,
    required this.day,
    this.endDay,
    required this.month,
    required this.year,
  });

  final String title;
  final String category;
  final int day;
  final int? endDay;
  final int month;
  final int year;

  Color get color => TripAgendaCategories.colorForKey(category);

  /// Inclusive end day for display / hit testing.
  int get effectiveEndDay => endDay ?? day;

  bool coversDay(int d, int month, int year) {
    if (this.month != month || this.year != year) return false;
    return d >= day && d <= effectiveEndDay;
  }
}

/// Web CalendarModal.jsx CATEGORIES — same keys and hex colors.
abstract final class TripAgendaCategories {
  static const List<(String key, Color color)> entries = [
    ('Flight', Color(0xFF3B82F6)),
    ('Hotel', Color(0xFF10B981)),
    ('Activity', Color(0xFF8B5CF6)),
    ('Dining', Color(0xFFF59E0B)),
    ('Transport', Color(0xFFEF4444)),
  ];

  static Color colorForKey(String key) {
    for (final e in entries) {
      if (e.$1 == key) return e.$2;
    }
    return entries[2].$2;
  }

  static List<String> get keys => entries.map((e) => e.$1).toList();
}
