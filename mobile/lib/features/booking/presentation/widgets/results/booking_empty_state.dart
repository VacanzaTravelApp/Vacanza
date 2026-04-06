import 'package:flutter/material.dart';

import 'package:mobile/core/theme/app_theme.dart';

/// Empty state shown when search returns zero results.
class BookingEmptyState extends StatelessWidget {
  final VoidCallback onModifySearch;

  const BookingEmptyState({super.key, required this.onModifySearch});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Icon(
            Icons.search_off_rounded,
            size: 32,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'No results found',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Try adjusting your filters or search criteria.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onModifySearch,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accent.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              'Modify Search',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
