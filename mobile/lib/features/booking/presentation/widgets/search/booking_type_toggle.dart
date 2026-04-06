import 'package:flutter/material.dart';

import 'package:mobile/core/theme/app_theme.dart';

import '../../cubit/booking_state.dart';

/// Segmented toggle for Hotels / Flights.
class BookingTypeToggle extends StatelessWidget {
  final BookingType selected;
  final ValueChanged<BookingType> onChanged;

  const BookingTypeToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    final track = cs.surfaceContainerHighest.withValues(alpha: 0.9);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Sliding indicator
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: selected == BookingType.hotels
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Buttons
          Row(
            children: [
              _tab(context, BookingType.hotels, Icons.hotel_rounded, 'Hotels',
                  accent, cs),
              _tab(context, BookingType.flights, Icons.flight_rounded, 'Flights',
                  accent, cs),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tab(
    BuildContext context,
    BookingType type,
    IconData icon,
    String label,
    Color accent,
    ColorScheme cs,
  ) {
    final isActive = selected == type;
    final inactiveMuted = cs.onSurfaceVariant;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(type),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? accent : inactiveMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? accent : inactiveMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
