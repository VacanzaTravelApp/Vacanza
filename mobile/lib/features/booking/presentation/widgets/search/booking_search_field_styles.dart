import 'package:flutter/material.dart';

/// Shared labels for hotel / flight search fields (readable, modern contrast).
abstract final class BookingSearchFieldStyles {
  static const Color labelColor = Color(0xFF1E293B);

  static const TextStyle fieldLabel = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.2,
    color: labelColor,
  );

  static const TextStyle dropdownValue = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Color(0xFF0F172A),
  );

  static const TextStyle dropdownMenuItem = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(0xFF0F172A),
  );

  /// Checkbox / inline row labels (e.g. Round trip).
  static const TextStyle inlineControlLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: labelColor,
  );
}
