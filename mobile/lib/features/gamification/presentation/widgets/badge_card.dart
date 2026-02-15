import 'package:flutter/material.dart';

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
    final colors = BadgeIconMapper.gradient(badge.key);
    final icon = BadgeIconMapper.icon(badge.key);

    return Opacity(
      opacity: badge.earned ? 1.0 : 0.40,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                gradient: LinearGradient(colors: colors),
                boxShadow: [
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              badge.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2C3E50)),
            ),
            // Earned checkmark
            if (badge.earned) ...[
              const SizedBox(height: 2),
              const Text('✓',
                  style: TextStyle(fontSize: 12, color: Color(0xFF2ECC71))),
            ],
          ],
        ),
      ),
    );
  }
}
