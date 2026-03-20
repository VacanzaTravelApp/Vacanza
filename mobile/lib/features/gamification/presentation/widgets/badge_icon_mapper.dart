import 'package:flutter/material.dart';

/// Maps backend badge keys to Material icons and gradient colors.
///
/// Backend seed keys: `speed`, `foodie`, `culture`, `nature`, `explorer`.
/// Unknown keys get a safe fallback (trophy icon / blue gradient).
class BadgeIconMapper {
  BadgeIconMapper._();

  /// Key → Material icon.
  static IconData icon(String key) {
    return switch (key) {
      'speed' => Icons.flash_on,
      'foodie' => Icons.restaurant,
      'culture' => Icons.museum,
      'nature' => Icons.park,
      'explorer' => Icons.explore,
      _ => Icons.emoji_events,
    };
  }

  /// Key → gradient colors for the badge circle.
  static List<Color> gradient(String key) {
    return switch (key) {
      'speed' => [const Color(0xFF9C27B0), const Color(0xFFBA68C8)],
      'foodie' => [const Color(0xFFFF6B6B), const Color(0xFFFFA07A)],
      'culture' => [const Color(0xFFE91E63), const Color(0xFFF06292)],
      'nature' => [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      'explorer' => [const Color(0xFFFFD166), const Color(0xFFF4A261)],
      _ => [const Color(0xFF0096FF), const Color(0xFF2ECC71)],
    };
  }
}
