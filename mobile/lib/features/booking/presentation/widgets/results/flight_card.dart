import 'package:flutter/material.dart';

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

  static const _accent = Color(0xFF0096FF);

  @override
  Widget build(BuildContext context) {
    final flight = widget.flight;
    final depTime = _formatTime(flight.departureTime);
    final arrTime = _formatTime(flight.arrivalTime);
    final dur = _formatDuration(flight.duration);
    final stopsLabel = _stopsLabel(flight.stops);
    final validUrl = isValidBookingUrl(flight.externalBookingUrl);
    final enabled = validUrl && !_isLaunching;

    return Container(
      padding: const EdgeInsets.all(14),
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
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF0F0F0)),
                ),
                child: Center(
                  child: Text(
                    flight.carrier,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF888888),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$depTime – $arrTime',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      flight.carrier,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${flight.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(flight.origin, style: _routeLabel),
                  Text(dur, style: _routeLabel),
                  Text(flight.destination, style: _routeLabel),
                ],
              ),
              const SizedBox(height: 4),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  if (flight.stops > 0)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFAAAAAA),
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
                      ? const Color(0xFFF0FFF4)
                      : const Color(0xFFFFF7ED),
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
                  color: const Color(0xFFFAFAFA),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLaunching ? 'Opening…' : 'Open in Google Flights',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF555555),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xFF555555),
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

  static const _routeLabel = TextStyle(
    fontSize: 11,
    color: Color(0xFF999999),
  );

  static String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  static String _formatDuration(String iso) {
    final match = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?').firstMatch(iso);
    if (match == null) return iso;
    final h = match.group(1);
    final m = match.group(2);
    final parts = <String>[];
    if (h != null) parts.add('${h}h');
    if (m != null) parts.add('${m}m');
    return parts.isEmpty ? iso : parts.join(' ');
  }

  static String _stopsLabel(int stops) {
    if (stops == 0) return 'Non-stop';
    if (stops == 1) return '1 stop';
    return '$stops stops';
  }
}
