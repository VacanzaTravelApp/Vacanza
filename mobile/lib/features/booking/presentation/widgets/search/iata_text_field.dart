import 'package:flutter/material.dart';

import 'package:mobile/core/theme/app_theme.dart';

import 'booking_search_field_styles.dart';

/// Reusable flight text field styled like other inputs.
class IataTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final IconData icon;

  /// e.g. trigger search when user taps keyboard "search".
  final VoidCallback? onSubmitted;

  const IataTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.placeholder,
    this.icon = Icons.search_rounded,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label,
            style: BookingSearchFieldStyles.fieldLabel(context).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onFieldSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: cs.onSurfaceVariant.withValues(alpha: 0.85),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(icon, size: 20, color: cs.onSurfaceVariant),
            filled: true,
            fillColor: BookingSearchFieldStyles.fieldFill(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: BookingSearchFieldStyles.fieldBorderInactive(context),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: BookingSearchFieldStyles.fieldBorderInactive(context),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: accent,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
