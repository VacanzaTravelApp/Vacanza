import 'package:flutter/material.dart';

import '../../../data/models/accommodation_option.dart';
import '../booking_url_launcher.dart';

/// Card displaying a single hotel result.
class HotelCard extends StatefulWidget {
  final AccommodationOption hotel;

  const HotelCard({super.key, required this.hotel});

  @override
  State<HotelCard> createState() => _HotelCardState();
}

class _HotelCardState extends State<HotelCard> {
  bool _isLaunching = false;

  static const _accent = Color(0xFF0096FF);

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
    final validUrl = isValidBookingUrl(hotel.externalBookingUrl);
    final enabled = validUrl && !_isLaunching;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF0F0F0)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hotel.hotelName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hotel.address.isNotEmpty ? hotel.address : 'Address not available',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          if (hotel.rating != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, size: 15, color: Color(0xFFFFD166)),
                  const SizedBox(width: 3),
                  Text(
                    hotel.rating!.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${hotel.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _accent,
                ),
              ),
              GestureDetector(
                onTap: enabled
                    ? () async {
                        setState(() => _isLaunching = true);
                        try {
                          await openBookingUrl(context, hotel.externalBookingUrl);
                        } finally {
                          if (mounted) setState(() => _isLaunching = false);
                        }
                      }
                    : null,
                child: Opacity(
                  opacity: enabled ? 1 : 0.5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _isLaunching ? 'Opening…' : 'Open booking',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _accent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
