import 'package:flutter/material.dart';

import '../../data/models/badge_dto.dart';

/// Single badge tile in the 3-column grid.
///
/// Badge key → icon / gradient mapping matches backend seed badge_keys:
/// `speed`, `foodie`, `culture`, `nature`, `explorer`.
class BadgeTile extends StatelessWidget {
  final BadgeDto badge;

  const BadgeTile({super.key, required this.badge});

  /// Map badge key → gradient colors (matching backend seeds).
  List<Color> get _gradient {
    return switch (badge.key) {
      'speed' => [const Color(0xFF9C27B0), const Color(0xFFBA68C8)],
      'foodie' => [const Color(0xFFFF6B6B), const Color(0xFFFFA07A)],
      'culture' => [const Color(0xFFE91E63), const Color(0xFFF06292)],
      'nature' => [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
      'explorer' => [const Color(0xFFFFD166), const Color(0xFFF4A261)],
      _ => [const Color(0xFF0096FF), const Color(0xFF2ECC71)],
    };
  }

  IconData get _icon {
    return switch (badge.key) {
      'speed' => Icons.bolt,
      'foodie' => Icons.restaurant,
      'culture' => Icons.account_balance,
      'nature' => Icons.park,
      'explorer' => Icons.explore,
      _ => Icons.emoji_events,
    };
  }

  @override
  Widget build(BuildContext context) {
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
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: _gradient),
                boxShadow: [
                  BoxShadow(
                    color: _gradient.first.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(_icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 8),
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
