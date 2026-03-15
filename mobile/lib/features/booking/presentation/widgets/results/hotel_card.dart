import 'package:flutter/material.dart';

import '../../../data/models/accommodation_option.dart';
import '../../../data/models/booking_utils.dart';
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
    final ratingText = formatRating(hotel.rating);

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          if (hotel.imageUrl != null && hotel.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                hotel.imageUrl!,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.hotel_rounded,
                color: Color(0xFFB0B0B0),
                size: 32,
              ),
            ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
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
                          const SizedBox(height: 2),
                          if (hotel.hotelClass != null)
                            Text(
                              '${hotel.hotelClass}★',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFEE9B00),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${hotel.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hotel.address.isNotEmpty
                      ? hotel.address
                      : 'Address not available',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 6),
                if (ratingText != null || hotel.totalReviews != null)
                  Row(
                    children: [
                      if (ratingText != null) ...[
                        const Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Color(0xFFFFD166),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          ratingText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                      if (ratingText != null && hotel.totalReviews != null)
                        const SizedBox(width: 6),
                      if (hotel.totalReviews != null)
                        Text(
                          '(${hotel.totalReviews} reviews)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                if (hotel.description != null &&
                    hotel.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    hotel.description!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
                if (hotel.providerName != null &&
                    hotel.providerName!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    hotel.providerName!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: enabled
                        ? () async {
                            setState(() => _isLaunching = true);
                            try {
                              await openBookingUrl(
                                  context, hotel.externalBookingUrl);
                            } finally {
                              if (mounted) {
                                setState(() => _isLaunching = false);
                              }
                            }
                          }
                        : null,
                    child: Opacity(
                      opacity: enabled ? 1 : 0.5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
