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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            'Adults',
            style: BookingSearchFieldStyles.fieldLabel,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            border: Border.all(color: const Color(0xFFE5E5E5)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _button(Icons.remove, value > 1, () => onChanged(value - 1)),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              _button(Icons.add, value < 10, () => onChanged(value + 1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _button(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? const Color(0xFF666666) : const Color(0xFFCCCCCC),
        ),
      ),
    );
  }
}
