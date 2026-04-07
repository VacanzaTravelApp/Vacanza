import 'package:flutter/material.dart';

import '../../data/models/badge_dto.dart';
import 'badge_card.dart';

/// Renders the badge grid section with title + 3-column grid.
///
/// Handles edge cases:
/// - Empty list → shows "No badges yet" placeholder
/// - Works for 0 / 1 / 5 / 20 badges
class BadgeGridSection extends StatelessWidget {
  final String sectionTitle;
  final List<BadgeDto> badges;

  const BadgeGridSection({
    super.key,
    required this.sectionTitle,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // ─── Empty state ───
    if (badges.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sectionTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
              ),
              child: Text(
                'No badges yet',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }

    // ─── Badge grid ───
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            sectionTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: badges.map((b) => BadgeCard(badge: b)).toList(),
          ),
        ),
      ],
    );
  }
}
