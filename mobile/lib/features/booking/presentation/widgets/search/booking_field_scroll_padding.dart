import 'package:flutter/material.dart';

/// Scroll padding for booking text fields inside the map modal bottom sheet.
///
/// Keeps the focused field and (for flights) airport autocomplete lists clear of
/// the keyboard when [MediaQuery.viewInsets] updates.
EdgeInsets bookingFieldScrollPadding(BuildContext context) {
  final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
  // Extra bottom space for flight autocomplete list; scroll view also adds
  // viewInsets so we avoid stacking huge margins.
  return EdgeInsets.fromLTRB(24, 88, 24, bottomInset + 180);
}
