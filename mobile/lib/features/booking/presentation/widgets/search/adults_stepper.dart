import 'package:flutter/material.dart';

import 'booking_search_field_styles.dart';

/// ± stepper for adult count, clamped 1–10.
class AdultsStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const AdultsStepper({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            'Adults',
            style: BookingSearchFieldStyles.fieldLabel(context),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: BookingSearchFieldStyles.fieldFill(context),
            border: Border.all(
              color: BookingSearchFieldStyles.fieldBorderInactive(context),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _button(context, Icons.remove, value > 1, () => onChanged(value - 1)),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
              ),
              _button(context, Icons.add, value < 10, () => onChanged(value + 1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _button(
    BuildContext context,
    IconData icon,
    bool enabled,
    VoidCallback onTap,
  ) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: cs.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.06),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? cs.onSurfaceVariant : cs.outline,
        ),
      ),
    );
  }
}
