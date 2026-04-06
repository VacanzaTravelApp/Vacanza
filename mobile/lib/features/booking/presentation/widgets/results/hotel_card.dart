import 'package:flutter/material.dart';

import 'package:mobile/core/theme/app_theme.dart';

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    final hotel = widget.hotel;
    final validUrl = isValidBookingUrl(hotel.externalBookingUrl);
    final enabled = validUrl && !_isLaunching;
    final ratingText = formatRating(hotel.rating);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
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
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.hotel_rounded,
                color: cs.onSurfaceVariant,
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
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (hotel.hotelClass != null)
                            Text(
                              'Class ${hotel.hotelClass}★',
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: accent,
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
                    color: cs.onSurfaceVariant,
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
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
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
                            color: cs.onSurfaceVariant,
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
                      color: cs.onSurface.withValues(alpha: 0.85),
                    ),
                  ),
                ],
                if (hotel.providerName != null &&
                    hotel.providerName!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    hotel.providerName!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
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
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _isLaunching ? 'Opening…' : 'Open booking',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: accent,
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
