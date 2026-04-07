import 'package:mobile/features/poi_search/data/models/poi.dart';

import '../domain/models/ar_poi.dart';
import 'geospatial_utils.dart';

ArPoi poiToArPoi(Poi p, double userLat, double userLng) {
  return ArPoi(
    id: p.poiId,
    name: p.name,
    categoryKey: p.category,
    distanceMeters: distanceMeters(
      lat1: userLat,
      lng1: userLng,
      lat2: p.latitude,
      lng2: p.longitude,
    ),
    bearingDegrees: bearingDegrees(
      lat1: userLat,
      lng1: userLng,
      lat2: p.latitude,
      lng2: p.longitude,
    ),
  );
}
