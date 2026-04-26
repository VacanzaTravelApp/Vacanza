import 'package:flutter/material.dart';

import 'package:mobile/core/theme/app_theme.dart';

import '../../../data/models/accommodation_option.dart';
import '../../../data/models/booking_utils.dart';
import '../booking_url_launcher.dart';
import '../search/booking_search_field_styles.dart';

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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final hotel = widget.hotel;
    final validUrl = isValidBookingUrl(hotel.externalBookingUrl);
    final enabled = validUrl && !_isLaunching;
    final ratingText = formatRating(hotel.rating);

    final borderColor = isLight
        ? const Color(0xFFE2E8F0)
        : BookingSearchFieldStyles.fieldBorderInactive(context);

    final cardShadows = isLight
        ? [
            const BoxShadow(
              color: Color(0x08000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
            const BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
            const BoxShadow(
              color: Color(0x05000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ]
        : [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ];

    return Container(
      decoration: BoxDecoration(
        color: isLight ? Colors.white : cs.surface,
        border: Border.all(color: borderColor, width: 1.2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: cardShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Main content row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                if (hotel.imageUrl != null && hotel.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      hotel.imageUrl!,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderThumb(cs),
                    ),
                  )
                else
                  _placeholderThumb(cs),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              hotel.hotelName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Price pill
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${hotel.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'per night',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Class badge
                      if (hotel.hotelClass != null) ...[
                        _StarBadge(hotelClass: hotel.hotelClass!),
                        const SizedBox(height: 4),
                      ],
                      // Address
                      if (hotel.address.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.place_outlined,
                                size: 12, color: cs.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                hotel.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      // Rating
                      if (ratingText != null || hotel.totalReviews != null) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            if (ratingText != null) ...[
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: const Color(0xFFFFB800),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                ratingText,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                            if (ratingText != null &&
                                hotel.totalReviews != null)
                              const SizedBox(width: 4),
                            if (hotel.totalReviews != null)
                              Text(
                                '(${hotel.totalReviews})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Description
          if (hotel.description != null &&
              hotel.description!.trim().isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                hotel.description!.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.72),
                  height: 1.45,
                ),
              ),
            ),
          ],

          // Provider
          if (hotel.providerName != null &&
              hotel.providerName!.trim().isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Text(
                hotel.providerName!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.70),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ── CTA button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _BookCta(
              label: 'Book Now',
              icon: Icons.open_in_new_rounded,
              accent: accent,
              enabled: enabled,
              loading: _isLaunching,
              onTap: enabled
                  ? () async {
                      setState(() => _isLaunching = true);
                      try {
                        await openBookingUrl(
                            context, hotel.externalBookingUrl);
                      } finally {
                        if (mounted) setState(() => _isLaunching = false);
                      }
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderThumb(ColorScheme cs) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.hotel_rounded,
        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
        size: 28,
      ),
    );
  }
}

// ── Star badge ────────────────────────────────────────────────────────────────

class _StarBadge extends StatelessWidget {
  final int hotelClass;
  const _StarBadge({required this.hotelClass});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        hotelClass.clamp(1, 5),
        (_) => const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFB800)),
      ),
    );
  }
}

// ── Shared CTA button ─────────────────────────────────────────────────────────

class _BookCta extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final bool enabled;
  final bool loading;
  final VoidCallback? onTap;

  const _BookCta({
    required this.label,
    required this.icon,
    required this.accent,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final bg = enabled
        ? accent
        : (isLight
            ? const Color(0xFFF1F5F9)
            : cs.onSurface.withValues(alpha: 0.08));
    final fg = enabled
        ? Colors.white
        : cs.onSurfaceVariant.withValues(alpha: 0.60);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fg,
                    ),
                  )
                else
                  Icon(icon, size: 14, color: fg),
                const SizedBox(width: 7),
                Text(
                  loading ? 'Opening…' : label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
