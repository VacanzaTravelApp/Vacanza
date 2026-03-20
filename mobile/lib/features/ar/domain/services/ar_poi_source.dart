import '../models/ar_poi.dart';

abstract class ArPoiSource {
  Future<List<ArPoi>> getNearbyArPois({
    required double lat,
    required double lng,
    List<String>? categories,
    double? radiusMeters,
  });
}

