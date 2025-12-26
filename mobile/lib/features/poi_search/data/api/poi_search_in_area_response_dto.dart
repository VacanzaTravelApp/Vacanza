import '../models/poi.dart';

class PoiSearchInAreaResponseDto {
  final int count;
  final List<Poi> pois;
  final Map<String, int> countsByCategory;

  const PoiSearchInAreaResponseDto({
    required this.count,
    required this.pois,
    required this.countsByCategory,
  });

  factory PoiSearchInAreaResponseDto.fromJson(Map<String, dynamic> json) {
    // pois listesi bazen null veya mixed type gelebilir -> güvenli parse
    final rawPois = (json["pois"] as List?) ?? const [];
    final pois = <Poi>[];

    for (final item in rawPois) {
      if (item is Map<String, dynamic>) {
        pois.add(Poi.fromJson(item));
      } else if (item is Map) {
        pois.add(Poi.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    // countsByCategory map'i bazen Map<dynamic,dynamic> gelebilir -> güvenli parse
    final rawCounts = json["countsByCategory"];
    final Map<String, dynamic> countsMap = (rawCounts is Map<String, dynamic>)
        ? rawCounts
        : (rawCounts is Map ? Map<String, dynamic>.from(rawCounts) : const {});

    final countsByCategory = countsMap.map(
          (k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0),
    );

    return PoiSearchInAreaResponseDto(
      count: (json["count"] as num?)?.toInt() ?? 0,
      pois: List.unmodifiable(pois),
      countsByCategory: Map.unmodifiable(countsByCategory),
    );
  }
}