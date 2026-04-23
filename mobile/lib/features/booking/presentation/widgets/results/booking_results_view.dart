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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary + filter row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${results.length} ${type == BookingType.hotels ? 'Hotels' : 'Flights'} Found',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: BookingSearchFieldStyles.fieldBorderInactive(context),
                  ),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: cs.onSurfaceVariant,
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
