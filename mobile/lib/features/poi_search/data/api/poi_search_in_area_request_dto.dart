import 'package:flutter/cupertino.dart';

import '../models/geo_point.dart';
import '../models/selected_area.dart';

enum PoiSort {
  ratingDesc,
  distanceToCenter,
}

extension PoiSortJson on PoiSort {
  String toJson() => switch (this) {
    PoiSort.ratingDesc => "RATING_DESC",
    PoiSort.distanceToCenter => "DISTANCE_TO_CENTER",
  };
}

class PoiSearchInAreaRequestDto {
  final SelectedArea area;
  final List<String>? categories;
  final int page;
  final int limit;
  final PoiSort? sort;

  PoiSearchInAreaRequestDto({
    required this.area,
    this.categories,
    this.page = 0,
    int? limit,
    this.sort,
  }) : limit = _normalizeLimit(limit);

  static int _normalizeLimit(int? limit) {
    final v = (limit == null || limit <= 0) ? 200 : limit;
    return v > 500 ? 500 : v; // FE enforce max 500
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      "page": page,
      "limit": limit,
    };

    if (sort != null) map["sort"] = sort!.toJson();

    // guide: gönderilmez/boş ise filtre yok
    if (categories != null && categories!.isNotEmpty) {
      map["categories"] = categories;
    }

    if (area is BboxArea) {
      final b = area as BboxArea;
      map["selectionType"] = "BBOX";
      map["bbox"] = {
        "minLat": b.minLat,
        "minLng": b.minLng,
        "maxLat": b.maxLat,
        "maxLng": b.maxLng,
      };
      return map;
    }

    if (area is PolygonArea) {
      final p = area as PolygonArea;

      // ekstra guard (PolygonArea zaten enforce ediyor ama DTO da güvenli olsun)
      if (p.points.length < 3) {
        throw ArgumentError("POLYGON requires at least 3 points.");
      }
      if (p.points.length > 200) {
        throw ArgumentError("POLYGON supports max 200 vertices.");
      }

      map["selectionType"] = "POLYGON";
      map["polygon"] = p.points
          .map((GeoPoint gp) => {"lat": gp.lat, "lng": gp.lng})
          .toList(growable: false);

      return map;
    }

    throw ArgumentError("SelectedArea must be BboxArea or PolygonArea.");
  }


}