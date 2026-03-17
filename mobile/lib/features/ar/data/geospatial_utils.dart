import 'dart:math' as math;

double _degToRad(double deg) => deg * math.pi / 180.0;
double _radToDeg(double rad) => rad * 180.0 / math.pi;

/// Haversine distance in meters between two lat/lng points.
double distanceMeters({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  const earthRadius = 6371000.0; // meters

  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lng2 - lng1);

  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degToRad(lat1)) *
          math.cos(_degToRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  return earthRadius * c;
}

/// Bearing from (lat1,lng1) to (lat2,lng2) in degrees, 0..360, relative to north.
double bearingDegrees({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  final phi1 = _degToRad(lat1);
  final phi2 = _degToRad(lat2);
  final dLon = _degToRad(lng2 - lng1);

  final y = math.sin(dLon) * math.cos(phi2);
  final x = math.cos(phi1) * math.cos(phi2) * math.cos(dLon) -
      math.sin(phi1) * math.sin(phi2);
  final brng = math.atan2(y, x);

  final deg = (_radToDeg(brng) + 360.0) % 360.0;
  return deg;
}

