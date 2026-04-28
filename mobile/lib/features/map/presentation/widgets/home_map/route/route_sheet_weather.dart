import 'package:flutter/material.dart';

import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/ai/utils/route_map.dart';

/// Horizontal weather strip + day-part hints for the route sheet header.
class RouteSheetWeather extends StatelessWidget {
  final RouteMapModel route;

  const RouteSheetWeather({super.key, required this.route});

  String _d(String? x) {
    if (x == null || x.length < 10) return x ?? '';
    return x.substring(5).replaceFirst('-', '/');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.vacanzaTokens;
    final wf = route.weatherForecast;
    if (wf.isEmpty && route.weatherDayParts.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weather',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: tokens.textMain,
          ),
        ),
        const SizedBox(height: 8),
        if (wf.isNotEmpty)
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: wf.length.clamp(0, 8),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final row = wf[i];
                return Container(
                  width: 108,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tokens.pillSurface.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tokens.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _d(row.date),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: tokens.textSub,
                        ),
                      ),
                      const Spacer(),
                      if (row.tempMaxCelsius != null &&
                          row.tempMinCelsius != null)
                        Text(
                          '${row.tempMaxCelsius!.round()}° / ${row.tempMinCelsius!.round()}°',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: tokens.textMain,
                          ),
                        ),
                      if (row.precipitationProbabilityMaxPercent != null)
                        Text(
                          'Rain ${row.precipitationProbabilityMaxPercent!.round()}%',
                          style: TextStyle(fontSize: 11, color: tokens.textSub),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (route.weatherDayParts.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Outdoor Conditions',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tokens.textSub,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: route.weatherDayParts.length.clamp(0, 5),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final d = route.weatherDayParts[i];
                return Container(
                  width: 96,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: tokens.pillSurface.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tokens.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _d(d.date),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: tokens.textMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _SlotRow(
                        icon: Icons.wb_twilight_rounded,
                        label: 'Morning',
                        avoid: d.morning?.avoidOutdoor == true,
                      ),
                      const SizedBox(height: 4),
                      _SlotRow(
                        icon: Icons.wb_sunny_rounded,
                        label: 'Afternoon',
                        avoid: d.afternoon?.avoidOutdoor == true,
                      ),
                      const SizedBox(height: 4),
                      _SlotRow(
                        icon: Icons.mode_night_rounded,
                        label: 'Evening',
                        avoid: d.evening?.avoidOutdoor == true,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.icon,
    required this.label,
    required this.avoid,
  });

  final IconData icon;
  final String label;
  final bool avoid;

  @override
  Widget build(BuildContext context) {
    final tokens = context.vacanzaTokens;
    const okColor = Color(0xFF22C55E);
    const cautionColor = Color(0xFFF59E0B);
    final color = avoid ? cautionColor : okColor;

    return Row(
      children: [
        Icon(icon, size: 10, color: tokens.textSub),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 9.5, color: tokens.textSub),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(
          avoid ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
          size: 11,
          color: color,
        ),
      ],
    );
  }
}
