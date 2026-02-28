import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/accommodation_option.dart';
import '../../../data/models/transport_option.dart';
import '../../cubit/booking_cubit.dart';
import '../../cubit/booking_state.dart';
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
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
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  size: 18,
                  color: Color(0xFF666666),
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
