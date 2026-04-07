import 'package:flutter/material.dart';

import '../../domain/models/ar_poi.dart';
import '../styles/ar_poi_style.dart';
import '../utils/ar_distance_format.dart';

/// Harita pinleri ile uyumlu: dolgu + halka rengi, mesafeye göre [scale] ile küçülür.
class ArPoiChip extends StatelessWidget {
  final ArPoi poi;
  final double scale;
  final bool isSelected;

  const ArPoiChip({
    super.key,
    required this.poi,
    this.scale = 1.0,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fill = arPoiFillColorForCategory(poi.categoryKey);
    final ring = arPoiRingColorForCategory(poi.categoryKey);
    final icon = arPoiIconForCategory(poi.categoryKey);

    final dist = formatArDistanceMeters(
      poi.distanceMeters,
      useImperial: localeUsesImperial(context),
    );

    final s = (isSelected ? scale * 1.06 : scale).clamp(0.5, 1.12);

    return Transform.scale(
      scale: s,
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: Material(
          color: cs.surface.withValues(alpha: 0.92),
          elevation: isSelected ? 6 : 3,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? cs.primary : ring.withValues(alpha: 0.95),
                width: isSelected ? 2.5 : 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fill.withValues(alpha: 0.95),
                    boxShadow: [
                      BoxShadow(
                        color: fill.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poi.name,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dist,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
