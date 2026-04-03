import 'package:flutter/material.dart';

/// Scrolls the parent [SingleChildScrollView] so a whole autocomplete block
/// (field + dropdown) stays above the keyboard.
///
/// Runs once after layout and again after a short delay so it still works when
/// the keyboard animation finishes after the first frame.
void scheduleBookingAutocompleteScrollIntoView(GlobalKey columnKey) {
  void scroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = columnKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: 0.02,
      );
    });
  }

  scroll();
  Future<void>.delayed(const Duration(milliseconds: 320), scroll);
}
