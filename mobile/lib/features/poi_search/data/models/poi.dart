import 'poi_category_catalog.dart';
import 'poi_data_source.dart';

class Poi {
  final String poiId;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final double? rating;
  final String? priceLevel;
  final String? externalId;

  /// [PoiDataSource.backend] | [PoiDataSource.mapboxStyle]
  final String source;

  const Poi({
    required this.poiId,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.rating,
    this.priceLevel,
    this.externalId,
    this.source = PoiDataSource.backend,
  });

  /// Check-in / backend eşleşmesi gereken akışlar için (sentetik Mapbox id yok)
  bool get isEligibleForBackendCheckin => source == PoiDataSource.backend;

  factory Poi.fromJson(Map<String, dynamic> json) {
    final lat = (json["latitude"] as num?)?.toDouble() ?? 0.0;
    final lng = (json["longitude"] as num?)?.toDouble() ?? 0.0;

    final category = (json["category"] ?? "").toString();
    final rawName = (json["name"] ?? "").toString();

    final name = PoiCategoryCatalog.safePoiTitle(
      name: rawName,
      rawCategory: category,
    );

    return Poi(
      poiId: (json["poiId"] ?? "").toString(),
      name: name,
      category: category,
      latitude: lat,
      longitude: lng,
      rating: (json["rating"] as num?)?.toDouble(),
      priceLevel: json["priceLevel"]?.toString(),
      externalId: json["externalId"]?.toString(),
      source: (json["source"] ?? PoiDataSource.backend).toString(),
    );
  }
}