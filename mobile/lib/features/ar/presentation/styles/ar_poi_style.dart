import 'package:flutter/material.dart';

Color arPoiColorForCategory(String categoryKey) {
  switch (categoryKey.toLowerCase()) {
    case 'restaurant':
      return const Color(0xFFE57373);
    case 'cafe':
      return const Color(0xFFBA68C8);
    case 'museum':
      return const Color(0xFF64B5F6);
    case 'monuments':
      return const Color(0xFFFFB74D);
    case 'parks':
      return const Color(0xFF81C784);
    default:
      return Colors.blueGrey;
  }
}

IconData arPoiIconForCategory(String categoryKey) {
  switch (categoryKey.toLowerCase()) {
    case 'restaurant':
      return Icons.restaurant;
    case 'cafe':
      return Icons.local_cafe;
    case 'museum':
      return Icons.museum;
    case 'monuments':
      return Icons.account_balance;
    case 'parks':
      return Icons.park;
    default:
      return Icons.place;
  }
}

