import 'dart:developer';

import '../models/poi.dart';
import '../models/selected_area.dart';
import 'polygon_contains.dart';

/// Backend + Mapbox stil POI birleştirme (dedupe, polygon kırpma).
class HybridPoiMerge {
  HybridPoiMerge._();

  static List<Poi> mergeBackendAndStyle({
    required SelectedArea area,
    required List<Poi> backendPois,
    required List<Poi> stylePois,
  }) {
    final all = <Poi>[...backendPois];
    final poiCoords = <String>{
      for (final p in backendPois)
        '${p.latitude.toStringAsFixed(4)},${p.longitude.toStringAsFixed(4)}',
    };

    for (final mbp in stylePois) {
      if (area is BboxArea && !_poiInBbox(mbp, area)) {
        continue;
      }
      final key =
          '${mbp.latitude.toStringAsFixed(4)},${mbp.longitude.toStringAsFixed(4)}';
      if (!poiCoords.contains(key)) {
        all.add(mbp);
        poiCoords.add(key);
      }
    }

    log(
      '[HybridPoiMerge] merged=${all.length} '
      '(backend=${backendPois.length} style=${stylePois.length})',
    );

    if (area is PolygonArea) {
      return all
          .where(
            (p) => pointInsidePolygonLatLng(
              lat: p.latitude,
              lng: p.longitude,
              polygonLatLng: area.points,
            ),
          )
          .toList();
    }

    return all;
  }

  static bool _poiInBbox(Poi p, BboxArea b) {
    return p.latitude >= b.minLat &&
        p.latitude <= b.maxLat &&
        p.longitude >= b.minLng &&
        p.longitude <= b.maxLng;
  }
}
