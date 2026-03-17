import 'package:flutter/material.dart';

import '../../domain/models/ar_poi.dart';
import '../styles/ar_poi_style.dart';

class ArPoiChip extends StatelessWidget {
  final ArPoi poi;

  const ArPoiChip({super.key, required this.poi});

  @override
  Widget build(BuildContext context) {
    final color = arPoiColorForCategory(poi.categoryKey);
    final icon = arPoiIconForCategory(poi.categoryKey);

    final dist = poi.distanceMeters >= 1000
        ? '${(poi.distanceMeters / 1000).toStringAsFixed(1)} km'
        : '${poi.distanceMeters.round()} m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.9), width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            poi.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 8),
          Text(
            dist,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

