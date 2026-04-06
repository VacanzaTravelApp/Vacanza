import 'package:flutter/material.dart';

import 'package:mobile/core/theme/app_theme.dart';

import '../../../data/models/booking_utils.dart';
import '../../../data/models/transport_option.dart';
import '../booking_url_launcher.dart';

/// Card displaying a single flight result.
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
    final flight = widget.flight;
    final depTime = formatTime(flight.departureTime);
    final arrTime = formatTime(flight.arrivalTime);
    final dur = formatDuration(flight.duration);
    final stopsLabel = formatStops(flight.stops);
    final validUrl = isValidBookingUrl(flight.externalBookingUrl);
    final enabled = validUrl && !_isLaunching;

    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cs.outline.withValues(alpha: 0.2),
                  ),
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
                          flight.carrier,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$depTime – $arrTime',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      [
                        flight.carrier,
                        if (flight.flightNumber != null &&
                            flight.flightNumber!.isNotEmpty)
                          flight.flightNumber!,
                      ].join(' · '),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${flight.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                  if (flight.travelClass != null &&
                      flight.travelClass!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          flight.travelClass!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(flight.origin, style: _routeLabel(context)),
                  Text(dur, style: _routeLabel(context)),
                  Text(flight.destination, style: _routeLabel(context)),
                ],
              ),
              const SizedBox(height: 4),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: cs.outline.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  if (flight.stops > 0)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: cs.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.onSurfaceVariant,
                          width: 2,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: flight.stops == 0
                      ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                      : const Color(0xFFF97316).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  stopsLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: flight.stops == 0
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF97316),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: enabled
                ? () async {
                    setState(() => _isLaunching = true);
                    try {
                      await openBookingUrl(context, flight.externalBookingUrl);
                    } finally {
                      if (mounted) setState(() => _isLaunching = false);
                    }
                  }
                : null,
            child: Opacity(
              opacity: enabled ? 1 : 0.5,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
                  border: Border.all(
                    color: cs.outline.withValues(alpha: 0.35),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLaunching ? 'Opening…' : 'Open in Google Flights',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _routeLabel(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextStyle(
      fontSize: 11,
      color: cs.onSurfaceVariant,
    );
  }
}
