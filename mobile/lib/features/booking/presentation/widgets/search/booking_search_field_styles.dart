import 'package:flutter/material.dart';

import 'package:mobile/core/theme/app_theme.dart';

abstract final class BookingSearchFieldStyles {
  // ── Label above fields ─────────────────────────────────────────────────────

  static TextStyle fieldLabel(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      height: 1.2,
      color: cs.onSurfaceVariant,
    );
  }

  // ── Dropdown value text ────────────────────────────────────────────────────

  static TextStyle dropdownValue(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    );
  }

  static TextStyle dropdownMenuItem(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    );
  }

  static TextStyle inlineControlLabel(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: cs.onSurface,
    );
  }

  // ── Field border ───────────────────────────────────────────────────────────

  /// Neutral gray border — no coral tint so fields read cleanly inside cards.
  static Color fieldBorderInactive(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return isLight
        ? const Color(0xFFDDE3EC)
        : cs.outline.withValues(alpha: 0.45);
  }

  // ── Field fill ─────────────────────────────────────────────────────────────

  /// Clearly distinct from the white card background so the field area reads.
  static Color fieldFill(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return isLight
        ? const Color(0xFFF7F9FB)
        : cs.surfaceContainerHighest.withValues(alpha: 0.55);
  }

  // ── Focused border ─────────────────────────────────────────────────────────

  static Color fieldBorderFocused(BuildContext context) =>
      context.mapControlAccent;
}

Color bookingAccentColor(BuildContext context) => context.mapControlAccent;
