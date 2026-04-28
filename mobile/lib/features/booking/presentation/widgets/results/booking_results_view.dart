import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/accommodation_option.dart';
import '../../../data/models/transport_option.dart';
import '../../cubit/booking_cubit.dart';
import '../../cubit/booking_state.dart';
import '../search/booking_search_field_styles.dart';
import 'flight_card.dart';
import 'hotel_card.dart';

/// Renders the results list with a summary header, filter icon, and cards.
class BookingResultsView extends StatelessWidget {
  final List<dynamic> results;
  final BookingType type;
  final String summary;

  const BookingResultsView({
    super.key,
    required this.results,
    required this.type,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary + filter row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${results.length} ${type == BookingType.hotels ? 'Hotels' : 'Flights'} Found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.read<BookingCubit>().openFilters(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isLight
                      ? Colors.white
                      : cs.surfaceContainerHighest.withValues(alpha: 0.70),
                  border: Border.all(
                    color: BookingSearchFieldStyles.fieldBorderInactive(context),
                    width: 1.2,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isLight
                      ? [
                          const BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded,
                        size: 15, color: cs.onSurfaceVariant),
                    const SizedBox(width: 5),
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Result cards
        ...results.map((item) {
          if (item is AccommodationOption) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HotelCard(hotel: item),
            );
          }
          if (item is TransportOption) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FlightCard(flight: item),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }
}
