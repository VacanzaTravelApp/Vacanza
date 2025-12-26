import 'package:flutter/cupertino.dart';

import '../models/geo_point.dart';
import '../models/selected_area.dart';
import 'poi_search_in_area_request_dto.dart';

void debugPoiSearchDto() {
  final bboxDto = PoiSearchInAreaRequestDto(
    area: BboxArea(
      minLat: 39.88,
      minLng: 32.75,
      maxLat: 39.95,
      maxLng: 32.90,
    ),
    categories: ["museum", "restaurant"],
    limit: 999, // 500'e kırpması lazım
    sort: PoiSort.distanceToCenter,
  );

  debugPrint("BBOX JSON => ${bboxDto.toJson()}");

  final polyDto = PoiSearchInAreaRequestDto(
    area: PolygonArea([
      const GeoPoint(lat: 39.90, lng: 32.80),
      const GeoPoint(lat: 39.92, lng: 32.88),
      const GeoPoint(lat: 39.95, lng: 32.83),
    ]),
    categories: ["cafe"],
    sort: PoiSort.ratingDesc,
  );

  debugPrint("POLYGON JSON => ${polyDto.toJson()}");
}