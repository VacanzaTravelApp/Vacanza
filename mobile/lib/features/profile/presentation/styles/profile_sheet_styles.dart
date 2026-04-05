import 'package:flutter/material.dart';

/// Shared style kit for Profile bottom sheets (Edit Profile, Edit Preferences).
/// Keeps sheets consistent; Auth screens use their own theme.
abstract final class ProfileSheetStyles {
  ProfileSheetStyles._();

  static const double sheetTopRadius = 24;

  /// Solid white bottom sheet panel (matches Vacanza theme; blur/frost variants
  /// can be reintroduced here later if needed).
  static Widget sheetPanel({
    required Widget child,
    BoxConstraints? constraints,
    double topRadius = sheetTopRadius,
  }) {
    return Container(
      constraints: constraints,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
      ),
      child: child,
    );
  }

  // ─── Colors ─────────────────────────────────────────────────────────────
  static const primaryBlue = Color(0xFF0096FF);
  static const focusBlue = Color(0xFF5BB8FF); // soft blue for focus, not bright

  // ─── Buttons ─────────────────────────────────────────────────────────────
  static const _buttonRadius = 14.0;
  static const _buttonHeight = 50.0;

  /// Primary "Save": solid Vacanza blue, no gradient, subtle shadow.
  static Widget primaryButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: _buttonHeight,
      child: Container(
        decoration: BoxDecoration(
          color: primaryBlue,
          borderRadius: BorderRadius.circular(_buttonRadius),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(_buttonRadius),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(_buttonRadius),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Secondary "Cancel": light gray filled, same radius/height, medium gray text.
  static Widget secondaryButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: _buttonHeight,
      child: Material(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(_buttonRadius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(_buttonRadius),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Inputs ───────────────────────────────────────────────────────────────
  /// Filled gray input; focus = soft blue border, no heavy glow.
  static InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: focusBlue, width: 1.2),
      ),
    );
  }
}
