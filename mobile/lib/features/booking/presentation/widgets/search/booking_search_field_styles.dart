import 'package:flutter/material.dart';

import 'package:mobile/core/theme/app_theme.dart';

/// Tema uyumlu booking arama alanı stilleri ([VacanzaTokens] / [ColorScheme]).
abstract final class BookingSearchFieldStyles {
  static TextStyle fieldLabel(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      height: 1.2,
      color: cs.onSurface,
    );
  }

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

  /// Varsayılan (odak dışı) çerçeve — light: [ColorScheme.secondary] (coral);
  /// dark: yumuşak [ColorScheme.outline].
  static Color fieldBorderInactive(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    if (isLight) return cs.secondary.withValues(alpha: 0.22);
    return cs.outline.withValues(alpha: 0.35);
  }

  /// Text field / dropdown fill — light: airy white; dark: muted surface.
  static Color fieldFill(BuildContext context) =>
      context.lightGlassFieldFill;
}

/// Odak / vurgu rengi — harita ile aynı [mapControlAccent].
Color bookingAccentColor(BuildContext context) =>
    context.mapControlAccent;
