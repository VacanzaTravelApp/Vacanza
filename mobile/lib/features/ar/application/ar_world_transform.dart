import 'dart:math' as math;

import '../domain/models/ar_poi.dart';

class ArWorldPlacement {
  final ArPoi poi;
  final double relativeBearingDeg;
  final double renderDistanceMeters;
  final double xMeters;
  final double yMeters;
  final double zMeters;

  const ArWorldPlacement({
    required this.poi,
    required this.relativeBearingDeg,
    required this.renderDistanceMeters,
    required this.xMeters,
    required this.yMeters,
    required this.zMeters,
  });
}

List<ArWorldPlacement> buildArWorldPlacements({
  required List<ArPoi> pois,
  required double deviceHeadingDeg,
  int maxPerCategory = 1,
  int maxTotal = 30,
  double minAngularSeparationDeg = 12.0,
  double minDistanceSeparationMeters = 20.0,
  double minRenderableDistanceMeters = 8.0,
  double maxRenderableDistanceMeters = 120.0,
  double nodeHeightMeters = -0.2,
}) {
  if (pois.isEmpty) return const [];

  final perCategoryCount = <String, int>{};
  final limited = <ArPoi>[];
  for (final poi in pois) {
    final current = perCategoryCount[poi.categoryKey] ?? 0;
    if (current >= maxPerCategory) continue;
    perCategoryCount[poi.categoryKey] = current + 1;
    limited.add(poi);
    if (limited.length >= maxTotal) break;
  }

  final sortedByDistance = [...limited]
    ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

  final accepted = <ArPoi>[];
  for (final candidate in sortedByDistance) {
    final candidateRel = signedRelativeAngleDeg(
      toBearingDeg: candidate.bearingDegrees,
      fromHeadingDeg: deviceHeadingDeg,
    );

    // Arkada kalanlar 3D etiket / düğüm olarak gösterilmez; UI’da alt bantta ok ile gösterilir.
    if (candidateRel.abs() > 90.0) {
      continue;
    }

    final hasCollision = accepted.any((other) {
      final otherRel = signedRelativeAngleDeg(
        toBearingDeg: other.bearingDegrees,
        fromHeadingDeg: deviceHeadingDeg,
      );
      final angularDelta = (candidateRel - otherRel).abs();
      final wrappedAngularDelta = math.min(angularDelta, 360.0 - angularDelta);
      final distanceDelta =
          (candidate.distanceMeters - other.distanceMeters).abs();
      // In AR world-anchor mode, POIs that share nearly the same bearing
      // collapse into one screen ray and look stacked. Prioritize angular
      // readability: keep only one POI per narrow angular slice.
      if (wrappedAngularDelta < minAngularSeparationDeg) return true;
      return wrappedAngularDelta < (minAngularSeparationDeg / 2) &&
          distanceDelta < minDistanceSeparationMeters;
    });

    if (!hasCollision) {
      accepted.add(candidate);
    }
  }

  return accepted.map((poi) {
    final rel = signedRelativeAngleDeg(
      toBearingDeg: poi.bearingDegrees,
      fromHeadingDeg: deviceHeadingDeg,
    );

    final relRad = rel * math.pi / 180.0;
    final renderDistance = poi.distanceMeters.clamp(
      minRenderableDistanceMeters,
      maxRenderableDistanceMeters,
    );

    // Local AR axes (typical): +x right, +y up, -z forward.
    final x = math.sin(relRad) * renderDistance;
    final z = -math.cos(relRad) * renderDistance;

    return ArWorldPlacement(
      poi: poi,
      relativeBearingDeg: rel,
      renderDistanceMeters: renderDistance,
      xMeters: x,
      yMeters: nodeHeightMeters,
      zMeters: z,
    );
  }).toList();
}

double normalizeHeadingDeg(double deg) {
  final normalized = deg % 360.0;
  return normalized < 0 ? normalized + 360.0 : normalized;
}

double normalizeSigned180(double deg) {
  var normalized = deg % 360.0;
  if (normalized > 180.0) normalized -= 360.0;
  if (normalized < -180.0) normalized += 360.0;
  return normalized;
}

double signedRelativeAngleDeg({
  required double toBearingDeg,
  required double fromHeadingDeg,
}) {
  return normalizeSigned180(toBearingDeg - fromHeadingDeg);
}
