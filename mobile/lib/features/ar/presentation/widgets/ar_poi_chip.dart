import 'package:flutter/material.dart';

import '../../domain/models/ar_poi.dart';
import '../styles/ar_poi_style.dart';
import '../utils/ar_distance_format.dart';

class ArPoiChip extends StatelessWidget {
  final ArPoi poi;
  final double scale;
  final bool isSelected;
  final VoidCallback? onTap;

  const ArPoiChip({
    super.key,
    required this.poi,
    this.scale = 1.0,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glowColor = arPoiRingColorForCategory(poi.categoryKey);
    final icon = arPoiIconForCategory(poi.categoryKey);
    final dist = formatArDistanceMeters(
      poi.distanceMeters,
      useImperial: localeUsesImperial(context),
    );

    final s = scale.clamp(0.5, 1.12);

    final Color bg;
    final Color nameColor;
    final List<BoxShadow> shadows;

    if (isDark) {
      bg = const Color(0xD9060613);
      nameColor = Colors.white;
      shadows = [
        BoxShadow(
          color: glowColor.withValues(alpha: isSelected ? 0.48 : 0.20),
          blurRadius: isSelected ? 22 : 12,
          spreadRadius: isSelected ? 1 : 0,
        ),
        const BoxShadow(
          color: Color(0x88000000),
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
      ];
    } else {
      bg = const Color(0xF2FFFFFF);
      nameColor = const Color(0xFF111827);
      shadows = [
        BoxShadow(
          color: glowColor.withValues(alpha: isSelected ? 0.32 : 0.14),
          blurRadius: isSelected ? 20 : 10,
          spreadRadius: isSelected ? 1 : 0,
        ),
        const BoxShadow(
          color: Color(0x33000000),
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
        const BoxShadow(
          color: Color(0x14000000),
          blurRadius: 2,
          offset: Offset(0, 1),
        ),
      ];
    }

    return Transform.scale(
      scale: s,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 175),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? glowColor.withValues(alpha: isDark ? 0.80 : 0.60)
                  : glowColor.withValues(alpha: isDark ? 0.38 : 0.30),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: shadows,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconOrb(glowColor: glowColor, icon: icon, isDark: isDark),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poi.name,
                      style: TextStyle(
                        color: nameColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dist,
                      style: TextStyle(
                        color: glowColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconOrb extends StatelessWidget {
  final Color glowColor;
  final IconData icon;
  final bool isDark;

  const _IconOrb({
    required this.glowColor,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: glowColor.withValues(alpha: isDark ? 0.15 : 0.12),
        border: Border.all(
          color: glowColor.withValues(alpha: isDark ? 0.50 : 0.45),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: isDark ? 0.35 : 0.22),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(icon, size: 15, color: glowColor),
    );
  }
}
