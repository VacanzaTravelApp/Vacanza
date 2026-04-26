import 'package:flutter/material.dart';

import 'package:mobile/core/theme/app_theme.dart';

import 'booking_search_field_styles.dart';

class IataTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final IconData icon;
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
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(label, style: BookingSearchFieldStyles.fieldLabel(context)),
        ),
        TextFormField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onFieldSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant.withValues(alpha: 0.60),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: BookingSearchFieldStyles.fieldFill(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: BookingSearchFieldStyles.fieldBorderInactive(context),
                width: 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: BookingSearchFieldStyles.fieldBorderInactive(context),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accent, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}
