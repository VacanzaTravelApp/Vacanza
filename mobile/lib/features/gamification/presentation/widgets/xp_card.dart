import 'package:flutter/material.dart';

import '../../data/models/gamification_profile_dto.dart';
import '../../data/models/stat_dto.dart';
import 'xp_ring_painter.dart';

/// Glass-style card showing XP progress ring and stats row.
class XpCard extends StatelessWidget {
  final GamificationProfileDto profile;

  const XpCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
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
              painter: XpRingPainter(profile.xpProgressPercent / 100.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${profile.xpProgressPercent}%',
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C3E50)),
                    ),
                    Text(
                      'to next level',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${profile.totalXp} XP',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ─── Stats row ───
          if (profile.stats.isNotEmpty) ...[
            const Divider(height: 1),
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
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 2),
                Text(
                  stat.label,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (!isLast)
            Container(
              width: 1,
              height: 40,
              color: const Color(0xFFE5E7EB),
            ),
        ];
      }).toList(),
    );
  }
}
