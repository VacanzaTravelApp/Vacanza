import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

import '../../data/models/badge_dto.dart';
import 'badge_icon_mapper.dart';

/// Renders a single badge from [BadgeDto].
///
/// - **earned** → full color, checkmark
/// - **unearned** → 40% opacity, greyed out
/// - Icon + gradient from [BadgeIconMapper], unknown key = safe fallback.
class BadgeCard extends StatelessWidget {
  final BadgeDto badge;

  const BadgeCard({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = BadgeIconMapper.gradient(badge.key);
    final icon = BadgeIconMapper.icon(badge.key);
    final accent = colors.first;

    return Opacity(
      opacity: badge.earned ? 1.0 : 0.40,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Requested: empty background, accent border/ring.
                color: cs.surface.withValues(alpha: 0.75),
                border: Border.all(color: accent.withValues(alpha: 0.70), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.12),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: accent, size: 26),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              badge.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            // Earned checkmark
            if (badge.earned) ...[
              const SizedBox(height: 2),
              Text(
                '✓',
                style: TextStyle(
                  fontSize: 12,
                  color: context.mapControlAccent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
