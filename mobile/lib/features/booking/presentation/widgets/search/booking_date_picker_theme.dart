import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

/// Shared theme wrapper for [showDatePicker] (flights) and
/// [showBookingHotelStayDateRange] (hotels) in booking.
Widget buildBookingDatePickerDialog(BuildContext context, Widget? child) {
  if (child == null) return const SizedBox.shrink();
  final accent = context.mapControlAccent;
  final baseTheme = Theme.of(context);
  final surface = baseTheme.colorScheme.surface;
  return Theme(
    data: baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: accent,
        onPrimary: Colors.white,
      ),
      datePickerTheme: baseTheme.datePickerTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        headerBackgroundColor: accent,
        headerForegroundColor: Colors.white,
        backgroundColor: surface,
      ),
    ),
    child: child,
  );
}
