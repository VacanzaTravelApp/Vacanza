import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/ar/presentation/utils/ar_distance_format.dart';

void main() {
  group('formatArDistanceMeters', () {
    test('metric uses m below 1000', () {
      expect(
        formatArDistanceMeters(42.3, useImperial: false),
        '42 m',
      );
    });

    test('metric uses km at and above 1000', () {
      expect(
        formatArDistanceMeters(1500, useImperial: false),
        '1.5 km',
      );
    });

    test('imperial uses ft below one mile', () {
      expect(
        formatArDistanceMeters(100, useImperial: true),
        '328 ft',
      );
    });

    test('imperial uses mi at one mile or more', () {
      expect(
        formatArDistanceMeters(1609.344, useImperial: true),
        '1.0 mi',
      );
    });
  });
}
