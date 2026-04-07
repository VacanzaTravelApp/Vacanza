import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

/// Placeholder section for live challenges (future feature).
class ChallengesPlaceholder extends StatelessWidget {
  const ChallengesPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.track_changes, size: 20, color: context.mapControlAccent),
            const SizedBox(width: 8),
            Text(
              'Live Challenges',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ],
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
            'Coming soon — complete check-ins to unlock challenges!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
