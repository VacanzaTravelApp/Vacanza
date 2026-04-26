import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/ar_world_transform.dart';
import '../../domain/models/ar_poi.dart';
import '../styles/ar_poi_style.dart';
import '../utils/ar_distance_format.dart';

class ArBehindPoiStrip extends StatelessWidget {
  const ArBehindPoiStrip({
    super.key,
    required this.pois,
    required this.deviceHeadingDeg,
    required this.onPoiTap,
    this.maxItems = 8,
    this.selectedPoiId,
  });

  final List<ArPoi> pois;
  final double deviceHeadingDeg;
  final void Function(ArPoi poi) onPoiTap;
  final int maxItems;
  final String? selectedPoiId;

  @override
  Widget build(BuildContext context) {
    if (pois.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final show = pois.take(maxItems).toList();

    final Color stripBg;
    final Color topBorder;
    final Color labelColor;

    if (isDark) {
      stripBg = const Color(0xD9060613);
      topBorder = const Color(0x26FFFFFF);
      labelColor = const Color(0x80FFFFFF);
    } else {
      stripBg = const Color(0xF2FFFFFF);
      topBorder = const Color(0x26000000);
      labelColor = const Color(0x80000000);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: stripBg,
        border: Border(
          top: BorderSide(color: topBorder, width: 0.8),
        ),
        boxShadow: isDark
            ? null
            : [
                const BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, -4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.rotate_right_rounded,
                size: 13,
                color: labelColor,
              ),
              const SizedBox(width: 5),
              Text(
                'Behind you  ·  ${show.length}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: show.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final poi = show[i];
                return _BehindPoiCard(
                  poi: poi,
                  deviceHeadingDeg: deviceHeadingDeg,
                  isSelected: selectedPoiId == poi.id,
                  isDark: isDark,
                  onTap: () => onPoiTap(poi),
                  useImperial: localeUsesImperial(context),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BehindPoiCard extends StatelessWidget {
  final ArPoi poi;
  final double deviceHeadingDeg;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  final bool useImperial;

  const _BehindPoiCard({
    required this.poi,
    required this.deviceHeadingDeg,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
    required this.useImperial,
  });

  @override
  Widget build(BuildContext context) {
    final glowColor = arPoiRingColorForCategory(poi.categoryKey);
    final icon = arPoiIconForCategory(poi.categoryKey);
    final rel = signedRelativeAngleDeg(
      toBearingDeg: poi.bearingDegrees,
      fromHeadingDeg: deviceHeadingDeg,
    );
    final dist = formatArDistanceMeters(
      poi.distanceMeters,
      useImperial: useImperial,
    );

    final Color cardBg;
    final Color nameColor;

    if (isDark) {
      cardBg = const Color(0xFF0C0C1E);
      nameColor = Colors.white;
    } else {
      cardBg = Colors.white;
      nameColor = const Color(0xFF111827);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 148),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? glowColor.withValues(alpha: 0.70)
                : glowColor.withValues(alpha: isDark ? 0.25 : 0.30),
            width: isSelected ? 1.4 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(
                alpha: isSelected ? 0.28 : (isDark ? 0.10 : 0.08),
              ),
              blurRadius: 10,
            ),
            if (!isDark)
              const BoxShadow(
                color: Color(0x14000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Direction arrow orb
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: glowColor.withValues(alpha: isDark ? 0.12 : 0.10),
                border: Border.all(
                  color: glowColor.withValues(alpha: isDark ? 0.38 : 0.40),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: isDark ? 0.25 : 0.18),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Transform.rotate(
                angle: rel * math.pi / 180.0,
                child: Icon(
                  Icons.navigation_rounded,
                  size: 13,
                  color: glowColor,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    poi.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: nameColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 9,
                        color: glowColor.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        dist,
                        style: TextStyle(
                          color: glowColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
