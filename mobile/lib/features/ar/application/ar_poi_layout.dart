import '../domain/models/ar_poi.dart';

class ArPoiPositioned {
  final ArPoi poi;
  /// 0..1 (0 = left, 1 = right)
  final double xFraction;
  /// Row index to reduce overlap (0, 1, ...)
  final int row;

  const ArPoiPositioned({
    required this.poi,
    required this.xFraction,
    required this.row,
  });
}

List<ArPoiPositioned> layoutArPois({
  required List<ArPoi> pois,
  required double deviceHeadingDeg,
  int maxPerCategory = 1,
  int maxTotal = 40,
}) {
  if (pois.isEmpty) return const [];

  double normalize(double angle) {
    var a = angle % 360;
    if (a > 180) a -= 360;
    if (a < -180) a += 360;
    return a;
  }

  // Limit POIs per category and in total so AR view stays readable.
  final perCategoryCount = <String, int>{};
  final limited = <ArPoi>[];
  for (final poi in pois) {
    final current = perCategoryCount[poi.categoryKey] ?? 0;
    if (current >= maxPerCategory) continue;
    perCategoryCount[poi.categoryKey] = current + 1;
    limited.add(poi);
    if (limited.length >= maxTotal) break;
  }

  final positioned = <ArPoiPositioned>[];

  final sorted = [...limited]
    ..sort((a, b) => a.bearingDegrees.compareTo(b.bearingDegrees));

  for (var i = 0; i < sorted.length; i++) {
    final poi = sorted[i];
    final rel = normalize(poi.bearingDegrees - deviceHeadingDeg); // -180..180

    // Approximate mapping: -90° => 0, +90° => 1
    final x = (rel + 90) / 180;
    final clampedX = x.clamp(0.0, 1.0);

    final row = i % 2;

    positioned.add(
      ArPoiPositioned(
        poi: poi,
        xFraction: clampedX,
        row: row,
      ),
    );
  }

  return positioned;
}

