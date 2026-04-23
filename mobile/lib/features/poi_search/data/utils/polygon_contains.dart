import '../models/geo_point.dart';

/// Ray casting; web [MapPage.jsx] `isPointInsidePolygon` ile aynı mantık.
bool pointInsidePolygonLatLng({
  required double lat,
  required double lng,
  required List<GeoPoint> polygonLatLng,
}) {
  if (polygonLatLng.length < 3) return false;
  var inside = false;
  for (var i = 0, j = polygonLatLng.length - 1;
      i < polygonLatLng.length;
      j = i++) {
    final xi = polygonLatLng[i].lng;
    final yi = polygonLatLng[i].lat;
    final xj = polygonLatLng[j].lng;
    final yj = polygonLatLng[j].lat;
    final intersect = (yi > lat) != (yj > lat) &&
        lng < (xj - xi) * (lat - yi) / (yj - yi + 0.0) + xi;
    if (intersect) inside = !inside;
  }
  return inside;
}
