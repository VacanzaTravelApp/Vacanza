import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/transport_option.dart';

/// Card displaying a single flight result.
class FlightCard extends StatelessWidget {
  final TransportOption flight;

  const FlightCard({super.key, required this.flight});

  static const _accent = Color(0xFF0096FF);

  @override
  Widget build(BuildContext context) {
    final depTime = _formatTime(flight.departureTime);
    final arrTime = _formatTime(flight.arrivalTime);
    final dur = _formatDuration(flight.duration);
    final stopsLabel = _stopsLabel(flight.stops);

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
          // Carrier + Time + Price row
          Row(
            children: [
              // Carrier badge
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
              // Times
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
              // Price
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

          // Route bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(flight.origin,
                      style: _routeLabel),
                  Text(dur, style: _routeLabel),
                  Text(flight.destination,
                      style: _routeLabel),
                ],
              ),
              const SizedBox(height: 4),
              // Progress bar
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
              // Stops badge
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

          // CTA button
          GestureDetector(
            onTap: () => _openBookingUrl(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                border: Border.all(color: const Color(0xFFE5E5E5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Open in Google Flights',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF555555),
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF555555)),
                ],
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

  /// Formats ISO 8601 datetime to "HH:mm".
  static String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Parses ISO 8601 duration (PT3H15M) to "3h 15m".
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

  Future<void> _openBookingUrl(BuildContext context) async {
    final uri = Uri.tryParse(flight.externalBookingUrl);
    if (uri == null || !uri.hasScheme) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking link unavailable')),
        );
      }
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open booking link')),
        );
      }
    }
  }
}
