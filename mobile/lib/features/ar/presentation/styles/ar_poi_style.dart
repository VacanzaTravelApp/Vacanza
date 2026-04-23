import 'package:flutter/material.dart';

import 'package:mobile/features/poi_search/data/models/poi_category_catalog.dart';

/// Harita marker’ları ile aynı kategori renkleri ([PoiCategoryCatalog]).
Color arPoiFillColorForCategory(String categoryKey) {
  final def = PoiCategoryCatalog.poiCategoryForRaw(categoryKey);
  return def?.fillColor ?? const Color(0xFF78909C);
}

Color arPoiRingColorForCategory(String categoryKey) {
  final def = PoiCategoryCatalog.poiCategoryForRaw(categoryKey);
  return def?.ringColor ?? arPoiFillColorForCategory(categoryKey);
}

IconData arPoiIconForCategory(String categoryKey) {
  final def = PoiCategoryCatalog.poiCategoryForRaw(categoryKey);
  return def?.iconData ?? Icons.place_rounded;
}

String? arPoiCategoryLabel(String categoryKey) {
  return PoiCategoryCatalog.labelForRawCategory(categoryKey);
}
