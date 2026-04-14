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
          const SizedBox(height: 8),
          Text(
            'Day parts — outdoor',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tokens.textSub,
            ),
          ),
          const SizedBox(height: 4),
          ...route.weatherDayParts
              .take(3)
              .map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${_d(d.date)} — m:${d.morning?.avoidOutdoor == true ? 'caution' : 'ok'} '
                    'a:${d.afternoon?.avoidOutdoor == true ? 'caution' : 'ok'} '
                    'e:${d.evening?.avoidOutdoor == true ? 'caution' : 'ok'}',
                    style: TextStyle(fontSize: 11.5, color: tokens.textSub),
                  ),
                ),
              ),
        ],
      ],
    );
  }
}
