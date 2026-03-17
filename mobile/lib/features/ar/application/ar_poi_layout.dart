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
}) {
  if (pois.isEmpty) return const [];

  double normalize(double angle) {
    var a = angle % 360;
    if (a > 180) a -= 360;
    if (a < -180) a += 360;
    return a;
  }

  final positioned = <ArPoiPositioned>[];

  final sorted = [...pois]
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

