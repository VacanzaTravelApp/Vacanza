import 'package:flutter/material.dart';

/// VACANZA-197: Marker renk/ölçü mapping'i
/// Filter panel ile aynı kategori->renk mantığını paylaşsın diye ayrı dosyada.
class PoiMarkerPalette {
  static Color colorFor(String category) {
    switch (category.trim().toLowerCase()) {
      case 'restaurants':
        return const Color(0xFFFFD166);
      case 'cafe':
        return const Color(0xFF6C63FF);
      case 'museum':
        return const Color(0xFF00C2FF);
      case 'monuments':
        return const Color(0xFFFF9F43);
      case 'parks':
        return const Color(0xFF2ECC71);
      default:
        return const Color(0xFF0096FF);
    }
  }

  static const double radius = 7.0;
  static const double strokeWidth = 1.6;
  static const Color strokeColor = Colors.white;
}