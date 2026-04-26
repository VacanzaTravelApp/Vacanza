import 'package:flutter/material.dart';

import 'package:mobile/core/theme/app_theme.dart';

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
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: BookingSearchFieldStyles.fieldFill(context),
            border: Border.all(
              color: BookingSearchFieldStyles.fieldBorderInactive(context),
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                enabled: value > 1,
                onTap: () => onChanged(value - 1),
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add_rounded,
                enabled: value < 10,
                onTap: () => onChanged(value + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.mapControlAccent;
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final bg = enabled
        ? accent.withValues(alpha: isLight ? 0.10 : 0.16)
        : cs.onSurface.withValues(alpha: 0.04);
    final borderCol = enabled
        ? accent.withValues(alpha: isLight ? 0.28 : 0.35)
        : cs.outline.withValues(alpha: 0.18);
    final iconCol = enabled
        ? accent
        : cs.onSurfaceVariant.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: borderCol, width: 1.2),
        ),
        child: Icon(icon, size: 17, color: iconCol),
      ),
    );
  }
}
