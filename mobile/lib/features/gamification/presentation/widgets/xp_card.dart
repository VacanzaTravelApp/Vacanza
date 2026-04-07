import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

import '../../data/models/gamification_profile_dto.dart';
import '../../data/models/stat_dto.dart';
import 'xp_ring_painter.dart';

/// Glass-style card showing XP progress ring and stats row.
class XpCard extends StatelessWidget {
  final GamificationProfileDto profile;

  const XpCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ringGradient = <Color>[
      ...context.mapControlActiveGradientColors,
      context.vacanzaTokens.vividAmber,
    ];
    return Container(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ─── Ring ───
          SizedBox(
            width: 192,
            height: 192,
            child: CustomPaint(
              painter: XpRingPainter(
                profile.xpProgressPercent / 100.0,
                trackColor: cs.outline.withValues(alpha: 0.22),
                gradientColors: ringGradient,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${profile.xpProgressPercent}%',
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface),
                    ),
                    Text(
                      'to next level',
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${profile.totalXp} XP',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ─── Stats row ───
          if (profile.stats.isNotEmpty) ...[
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.18)),
            const SizedBox(height: 16),
            _StatsRow(stats: profile.stats),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────── Stats Row ──────────────────────────

class _StatsRow extends StatelessWidget {
  final List<StatDto> stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: stats.asMap().entries.expand((entry) {
        final stat = entry.value;
        final isLast = entry.key == stats.length - 1;
        return [
          Expanded(
            child: Column(
              children: [
                Text(
                  '${stat.value}',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  stat.label,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (!isLast)
            Container(
              width: 1,
              height: 40,
              color: cs.outline.withValues(alpha: 0.18),
            ),
        ];
      }).toList(),
    );
  }
}
