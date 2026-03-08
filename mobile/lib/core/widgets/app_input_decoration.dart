import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
  /// Focused state uses [AppColors.primary]; enabled uses [AppColors.inputBorder].
  static InputDecoration decoration({
    String? hintText,
    String? labelText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      hintStyle: const TextStyle(color: AppColors.inputPlaceholder),
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      enabledBorder: _border(AppColors.inputBorder),
      focusedBorder: _border(AppColors.primary),
      errorBorder: _border(Colors.red),
      focusedErrorBorder: _border(Colors.red),
      suffixIcon: suffixIcon,
    );
  }
}
