import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_compass/flutter_compass.dart';

class DeviceHeadingService {
  const DeviceHeadingService();

  Stream<double> headingStream({
    double minDeltaDeg = 1.5,
    double smoothingFactor = 0.25,
  }) {
    final events = FlutterCompass.events;
    if (events == null) {
      return const Stream<double>.empty();
    }

    final effectiveSmoothing = smoothingFactor.clamp(0.0, 1.0);
    final effectiveMinDelta = math.max(0.0, minDeltaDeg);

    double? lastSmoothedHeading;
    double? lastEmittedHeading;

    return events
        .map((event) {
          final raw = event.heading;
          if (raw == null || !raw.isFinite) {
            return null;
          }

          final normalizedRaw = normalizeHeadingDeg(raw);

          if (lastSmoothedHeading == null) {
            lastSmoothedHeading = normalizedRaw;
          } else {
            final delta = _signedShortestDeltaDeg(
              fromDeg: lastSmoothedHeading!,
              toDeg: normalizedRaw,
            );
            lastSmoothedHeading = normalizeHeadingDeg(
              lastSmoothedHeading! + delta * effectiveSmoothing,
            );
          }

          if (lastEmittedHeading == null) {
            lastEmittedHeading = lastSmoothedHeading;
            return lastSmoothedHeading;
          }

          final movedDeg = _absShortestDeltaDeg(
            aDeg: lastEmittedHeading!,
            bDeg: lastSmoothedHeading!,
          );
          if (movedDeg < effectiveMinDelta) {
            return null;
          }

          lastEmittedHeading = lastSmoothedHeading;
          return lastSmoothedHeading;
        })
        .where((heading) => heading != null)
        .cast<double>();
  }
}

double normalizeHeadingDeg(double deg) {
  final normalized = deg % 360.0;
  return normalized < 0 ? normalized + 360.0 : normalized;
}

double _signedShortestDeltaDeg({
  required double fromDeg,
  required double toDeg,
}) {
  final from = normalizeHeadingDeg(fromDeg);
  final to = normalizeHeadingDeg(toDeg);
  var delta = to - from;
  if (delta > 180.0) delta -= 360.0;
  if (delta < -180.0) delta += 360.0;
  return delta;
}

double _absShortestDeltaDeg({required double aDeg, required double bDeg}) {
  return _signedShortestDeltaDeg(fromDeg: aDeg, toDeg: bDeg).abs();
}
