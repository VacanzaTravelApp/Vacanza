import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Input decoration consistent with Auth (Login/Register) theme.
/// Use for TextField/InputDecorator: same fill, border radius, and focus border as [AppTextField].
class AppInputDecoration {
  AppInputDecoration._();

  static const _radius = 24.0;

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide(color: color, width: 1.4),
      );

  /// Returns [InputDecoration] with Auth-like enabled/focused borders.
  /// Theme-aware: uses tokens + [ColorScheme].
  static InputDecoration decoration({
    String? hintText,
    String? labelText,
    Widget? suffixIcon,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final tokens = context.vacanzaTokens;
    final isLight = theme.brightness == Brightness.light;
    final accent = context.authAccent;

    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      hintStyle: TextStyle(
        color: tokens.textSub.withValues(alpha: isLight ? 0.70 : 0.62),
      ),
      filled: true,
      fillColor: isLight ? context.lightGlassFieldFill : tokens.pillSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      enabledBorder: _border(tokens.cardBorder),
      focusedBorder: _border(accent),
      errorBorder: _border(Colors.red),
      focusedErrorBorder: _border(Colors.red),
      suffixIcon: suffixIcon,
    );
  }
}
