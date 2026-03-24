import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ar/data/device_heading_service.dart';

void main() {
  group('normalizeHeadingDeg', () {
    test('normalizes negative values into 0..360 range', () {
      expect(normalizeHeadingDeg(-10), closeTo(350, 0.0001));
    });

    test('normalizes values above 360 into 0..360 range', () {
      expect(normalizeHeadingDeg(370), closeTo(10, 0.0001));
    });

    test('keeps already-normalized heading unchanged', () {
      expect(normalizeHeadingDeg(125.5), closeTo(125.5, 0.0001));
    });
  });
}
