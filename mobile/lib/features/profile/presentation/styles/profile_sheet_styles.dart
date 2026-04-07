import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/booking/presentation/widgets/search/booking_search_field_styles.dart';

/// Shared style kit for Profile bottom sheets (Edit Profile, Edit Preferences).
/// Keeps sheets consistent; Auth screens use their own theme.
abstract final class ProfileSheetStyles {
  ProfileSheetStyles._();

  static const double sheetTopRadius = 24;

  /// Solid white bottom sheet panel (matches Vacanza theme; blur/frost variants
  /// can be reintroduced here later if needed).
  static Widget sheetPanel({
    required BuildContext context,
    required Widget child,
    BoxConstraints? constraints,
    double topRadius = sheetTopRadius,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: constraints,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(topRadius)),
      ),
      child: child,
    );
  }

  // ─── Buttons ─────────────────────────────────────────────────────────────
  static const _buttonRadius = 14.0;
  static const _buttonHeight = 50.0;

  /// Primary "Save": solid Vacanza blue, no gradient, subtle shadow.
  static Widget primaryButton({
    required BuildContext context,
    required String text,
    required VoidCallback? onPressed,
  }) {
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    return SizedBox(
      height: _buttonHeight,
      child: Container(
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(_buttonRadius),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.25),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onPrimary,
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
    required BuildContext context,
    required String text,
    required VoidCallback? onPressed,
  }) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: _buttonHeight,
      child: Material(
        color: cs.surfaceContainerHighest,
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
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Inputs ───────────────────────────────────────────────────────────────
  /// Filled input — secondary-style border in light, outline in dark.
  static InputDecoration inputDecoration(BuildContext context, String hint) {
    final accent = context.mapControlAccent;
    final borderColor = BookingSearchFieldStyles.fieldBorderInactive(context);
    final fill = BookingSearchFieldStyles.fieldFill(context);
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.85)),
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
    );
  }
}
