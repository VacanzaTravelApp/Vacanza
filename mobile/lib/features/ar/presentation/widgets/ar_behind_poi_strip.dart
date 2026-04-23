import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:mobile/features/poi_search/data/models/poi_category_catalog.dart';

import '../../application/ar_world_transform.dart';
import '../../domain/models/ar_poi.dart';
import '../styles/ar_poi_style.dart';
import '../utils/ar_distance_format.dart';

/// Telefonun baktığı yöne göre arkada kalan POI’lar — alt bantta ok ile yön.
class ArBehindPoiStrip extends StatelessWidget {
  const ArBehindPoiStrip({
    super.key,
    required this.pois,
    required this.deviceHeadingDeg,
    required this.onPoiTap,
    this.maxItems = 10,
    this.selectedPoiId,
  });

  final List<ArPoi> pois;
  final double deviceHeadingDeg;
  final void Function(ArPoi poi) onPoiTap;
  final int maxItems;
  final String? selectedPoiId;

  static const double _cardHeight = 96;

  @override
  Widget build(BuildContext context) {
    if (pois.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final show = pois.take(maxItems).toList();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.surface.withValues(alpha: 0.55),
              cs.surface.withValues(alpha: 0.88),
            ],
          ),
          border: Border(
            top: BorderSide(color: cs.outline.withValues(alpha: 0.25)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.explore_rounded,
                  size: 18,
                  color: cs.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Behind you',
                  style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: cs.onSurface,
                      ) ??
                      TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: cs.onSurface,
                      ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Turn to face them',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: _cardHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: show.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final poi = show[index];
                  final rel = signedRelativeAngleDeg(
                    toBearingDeg: poi.bearingDegrees,
                    fromHeadingDeg: deviceHeadingDeg,
                  );
                  final fill = arPoiFillColorForCategory(poi.categoryKey);
                  final ring = arPoiRingColorForCategory(poi.categoryKey);
                  final icon = arPoiIconForCategory(poi.categoryKey);
                  final label =
                      PoiCategoryCatalog.labelForRawCategory(poi.categoryKey) ??
                      poi.categoryKey;
                  final dist = formatArDistanceMeters(
                    poi.distanceMeters,
                    useImperial: localeUsesImperial(context),
                  );
                  final isSelected =
                      selectedPoiId != null && selectedPoiId == poi.id;

                  return SizedBox(
                    width: 152,
                    height: _cardHeight,
                    child: Material(
                      color: cs.surface.withValues(alpha: 0.97),
                      borderRadius: BorderRadius.circular(14),
                      elevation: isSelected ? 4 : 2,
                      shadowColor: Colors.black26,
                      child: InkWell(
                        onTap: () => onPoiTap(poi),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? cs.primary
                                  : ring.withValues(alpha: 0.75),
                              width: isSelected ? 2.5 : 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: fill,
                                    ),
                                    child: Icon(
                                      icon,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Transform.rotate(
                                      angle: rel * math.pi / 180.0,
                                      child: Icon(
                                        Icons.navigation_rounded,
                                        size: 22,
                                        color: cs.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Text(
                                  poi.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                              Text(
                                '$dist · $label',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
