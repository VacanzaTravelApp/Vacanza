import 'package:flutter/material.dart';

import 'package:mobile/core/theme/app_theme.dart';

import '../../../data/models/booking_utils.dart';
import '../../../data/models/transport_option.dart';
import '../booking_url_launcher.dart';
import '../search/booking_search_field_styles.dart';

class FlightCard extends StatefulWidget {
  final TransportOption flight;

  const FlightCard({super.key, required this.flight});

  @override
  State<FlightCard> createState() => _FlightCardState();
}

class _FlightCardState extends State<FlightCard> {
  bool _isLaunching = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final flight = widget.flight;
    final depTime = formatTime(flight.departureTime);
    final arrTime = formatTime(flight.arrivalTime);
    final dur = formatDuration(flight.duration);
    final stopsLabel = formatStops(flight.stops);
    final validUrl = isValidBookingUrl(flight.externalBookingUrl);
    final enabled = validUrl && !_isLaunching;

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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Column(
              children: [
                // ── Airline row ──
                Row(
                  children: [
                    // Airline logo / initials
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isLight
                            ? const Color(0xFFF8FAFC)
                            : cs.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 1),
                        image: flight.airlineLogo != null &&
                                flight.airlineLogo!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(flight.airlineLogo!),
                                fit: BoxFit.contain,
                              )
                            : null,
                      ),
                      child: (flight.airlineLogo == null ||
                              flight.airlineLogo!.isEmpty)
                          ? Center(
                              child: Text(
                                flight.carrier.length > 2
                                    ? flight.carrier.substring(0, 2)
                                    : flight.carrier,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    // Carrier + flight number
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [
                              flight.carrier,
                              if (flight.flightNumber != null &&
                                  flight.flightNumber!.isNotEmpty)
                                flight.flightNumber!,
                            ].join(' · '),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          if (flight.travelClass != null &&
                              flight.travelClass!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accent.withValues(
                                      alpha: isLight ? 0.10 : 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  flight.travelClass!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: accent,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${flight.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: accent,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'per person',
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

                const SizedBox(height: 16),

                // ── Route timeline ──
                _FlightTimeline(
                  origin: flight.origin,
                  destination: flight.destination,
                  depTime: depTime,
                  arrTime: arrTime,
                  duration: dur,
                  stops: flight.stops,
                  stopsLabel: stopsLabel,
                  accent: accent,
                  isLight: isLight,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── CTA button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _BookCta(
              label: 'View on Google Flights',
              icon: Icons.flight_takeoff_rounded,
              accent: accent,
              enabled: enabled,
              loading: _isLaunching,
              onTap: enabled
                  ? () async {
                      setState(() => _isLaunching = true);
                      try {
                        await openBookingUrl(
                            context, flight.externalBookingUrl);
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
}

// ── Flight timeline ───────────────────────────────────────────────────────────

class _FlightTimeline extends StatelessWidget {
  final String origin;
  final String destination;
  final String depTime;
  final String arrTime;
  final String duration;
  final int stops;
  final String stopsLabel;
  final Color accent;
  final bool isLight;

  const _FlightTimeline({
    required this.origin,
    required this.destination,
    required this.depTime,
    required this.arrTime,
    required this.duration,
    required this.stops,
    required this.stopsLabel,
    required this.accent,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final direct = stops == 0;
    final stopColor = direct
        ? const Color(0xFF22C55E)
        : const Color(0xFFF97316);
    final lineColor = isLight
        ? accent.withValues(alpha: 0.35)
        : accent.withValues(alpha: 0.25);

    return Column(
      children: [
        // Times + duration row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _timeCol(context, depTime, origin, cs),
            Expanded(
              child: Column(
                children: [
                  Text(
                    duration,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Route line
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: lineColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      // Plane icon in center
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        color: Colors.transparent,
                        child: Icon(
                          Icons.flight_rounded,
                          size: 14,
                          color: accent,
                        ),
                      ),
                      if (stops > 0)
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isLight ? Colors.white : cs.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: stopColor, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Stops badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: stopColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      stopsLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: stopColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _timeCol(context, arrTime, destination, cs, alignRight: true),
          ],
        ),
      ],
    );
  }

  Widget _timeCol(
    BuildContext context,
    String time,
    String code,
    ColorScheme cs, {
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            height: 1.1,
          ),
        ),
        Text(
          code,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
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
