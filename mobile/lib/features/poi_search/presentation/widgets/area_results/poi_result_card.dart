import 'package:flutter/material.dart';

import '../../../data/models/poi.dart';

class PoiResultCard extends StatelessWidget {
  final Poi poi;

  const PoiResultCard({
    super.key,
    required this.poi,
  });

  @override
  Widget build(BuildContext context) {
    final title = (poi.name?.trim().isNotEmpty ?? false) ? poi.name!.trim() : 'Unnamed place';
    final category = poi.category.trim().isEmpty ? 'place' : poi.category.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          _CategoryDot(category: category),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Şimdilik placeholder.
          // İleride: "Add to route" / distance / navigate vs.
          Text(
            '→',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black.withValues(alpha: 0.35),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryDot extends StatelessWidget {
  final String category;
  const _CategoryDot({required this.category});

  Color _colorFor(String key) {
    final k = key.trim().toLowerCase();
    switch (k) {
      case 'restaurant':
        return const Color(0xFFFFD166);
      case 'cafe':
        return const Color(0xFFB37AFF);
      case 'museum':
        return const Color(0xFF0096FF);
      case 'monuments':
        return const Color(0xFFFF9F43);
      case 'parks':
        return const Color(0xFF2ECC71);
      default:
        return const Color(0xFF0096FF);
    }
  }

  IconData _iconFor(String key) {
    final k = key.trim().toLowerCase();
    switch (k) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'cafe':
        return Icons.local_cafe_rounded;
      case 'museum':
        return Icons.museum_rounded;
      case 'monuments':
        return Icons.account_balance_rounded;
      case 'parks':
        return Icons.park_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(category);

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _iconFor(category),
        size: 20,
        color: color,
      ),
    );
  }
}