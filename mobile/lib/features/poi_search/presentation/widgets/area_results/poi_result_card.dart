import 'package:flutter/material.dart';

import '../../../data/models/poi.dart';
import '../../../data/models/poi_category_catalog.dart';

class PoiResultCard extends StatelessWidget {
  final Poi poi;

  const PoiResultCard({
    super.key,
    required this.poi,
  });

  @override
  Widget build(BuildContext context) {
    final title = PoiCategoryCatalog.safePoiTitle(
      name: poi.name,
      rawCategory: poi.category,
    );
    final categoryLabel =
        PoiCategoryCatalog.labelForRawCategory(poi.category) ??
            (poi.category.trim().isEmpty ? 'place' : poi.category.trim());

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
          _CategoryDot(rawCategory: poi.category),
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
                  categoryLabel,
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
  final String rawCategory;
  const _CategoryDot({required this.rawCategory});

  @override
  Widget build(BuildContext context) {
    final def = PoiCategoryCatalog.poiCategoryForRaw(rawCategory);
    final color = def?.ringColor ?? const Color(0xFF0096FF);
    final icon = def?.iconData ?? Icons.place_rounded;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 20,
        color: color,
      ),
    );
  }
}