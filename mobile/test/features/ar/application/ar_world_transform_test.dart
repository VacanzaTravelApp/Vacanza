import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ar/application/ar_world_transform.dart';
import 'package:mobile/features/ar/domain/models/ar_poi.dart';

void main() {
  group('buildArWorldPlacements', () {
    test('keeps farther POI farther in world space', () {
      const near = ArPoi(
        id: 'near',
        name: 'Near',
        categoryKey: 'food',
        distanceMeters: 20,
        bearingDegrees: 0,
      );
      const far = ArPoi(
        id: 'far',
        name: 'Far',
        categoryKey: 'park',
        distanceMeters: 80,
        bearingDegrees: 0,
      );

      final placements = buildArWorldPlacements(
        pois: const [near, far],
        deviceHeadingDeg: 0,
        maxPerCategory: 1,
        minAngularSeparationDeg: 0,
      );

      expect(placements.length, 2);
      final nearPlacement = placements.firstWhere((p) => p.poi.id == 'near');
      final farPlacement = placements.firstWhere((p) => p.poi.id == 'far');

      expect(
        farPlacement.renderDistanceMeters,
        greaterThan(nearPlacement.renderDistanceMeters),
      );
      expect(
        farPlacement.zMeters.abs(),
        greaterThan(nearPlacement.zMeters.abs()),
      );
    });

    test('normalizes relative angle around 360 wrap', () {
      final rel = signedRelativeAngleDeg(toBearingDeg: 5, fromHeadingDeg: 355);
      expect(rel, closeTo(10, 0.0001));
    });

    test('filters near-identical bearings to avoid stacked anchors', () {
      const near = ArPoi(
        id: 'near',
        name: 'Near',
        categoryKey: 'food',
        distanceMeters: 20,
        bearingDegrees: 10,
      );
      const far = ArPoi(
        id: 'far',
        name: 'Far',
        categoryKey: 'park',
        distanceMeters: 80,
        bearingDegrees: 11,
      );

      final placements = buildArWorldPlacements(
        pois: const [near, far],
        deviceHeadingDeg: 0,
        maxPerCategory: 1,
      );

      expect(placements.length, 1);
      expect(placements.first.poi.id, 'near');
    });
  });
}
