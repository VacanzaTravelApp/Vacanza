import 'package:flutter/material.dart';

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

  static const _accent = Color(0xFF0096FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5).withValues(alpha: 0.8),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
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
              _tab(BookingType.hotels, Icons.hotel_rounded, 'Hotels'),
              _tab(BookingType.flights, Icons.flight_rounded, 'Flights'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tab(BookingType type, IconData icon, String label) {
    final isActive = selected == type;
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
                color: isActive ? _accent : const Color(0xFF999999),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isActive ? _accent : const Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
