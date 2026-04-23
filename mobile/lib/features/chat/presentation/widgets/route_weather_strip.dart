import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/chat_models.dart';

class RouteWeatherStrip extends StatelessWidget {
  final ChatRouteData route;

  const RouteWeatherStrip({super.key, required this.route});

  String _shortDate(String? d) {
    if (d == null || d.length < 10) return d ?? '';
    return d.substring(5).replaceFirst('-', '/');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    final wf = route.weatherForecast;
    if (wf.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: wf.length.clamp(0, 5),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final row = wf[i];
          final tMax = row.tempMaxCelsius;
          final tMin = row.tempMinCelsius;
          final precip = row.precipitationProbabilityMaxPercent;
          return Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.light
                      ? Color.alphaBlend(
                        accent.withValues(alpha: 0.10),
                        cs.surface,
                      )
                      : cs.surfaceContainerHighest.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.cardBorder.withValues(alpha: 0.55)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _shortDate(row.date),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: t.textSub.withValues(alpha: 0.85),
                  ),
                ),
                const Spacer(),
                if (tMax != null && tMin != null)
                  Text(
                    '${tMax.round()}° / ${tMin.round()}°',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: t.textMain,
                    ),
                  ),
                if (precip != null)
                  Text(
                    'Rain ${precip.round()}%',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: accent.withValues(alpha: 0.90),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

