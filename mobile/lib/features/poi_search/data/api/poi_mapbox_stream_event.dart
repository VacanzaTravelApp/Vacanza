import '../models/poi.dart';

sealed class PoiMapboxStreamEvent {
  const PoiMapboxStreamEvent();
}

class PoiMapboxStreamChunk extends PoiMapboxStreamEvent {
  final String uiCategory;
  final int chunkIndex;
  final List<Poi> pois;
  final Map<String, int> countsSoFar;

  const PoiMapboxStreamChunk({
    required this.uiCategory,
    required this.chunkIndex,
    required this.pois,
    required this.countsSoFar,
  });

  factory PoiMapboxStreamChunk.fromJson(Map<String, dynamic> json) {
    final rawPois = (json['pois'] as List?) ?? const [];
    final pois = <Poi>[];
    for (final item in rawPois) {
      if (item is Map<String, dynamic>) {
        pois.add(Poi.fromJson(item));
      } else if (item is Map) {
        pois.add(Poi.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    final rawCounts = json['countsSoFar'];
    final Map<String, dynamic> countsMap = switch (rawCounts) {
      final Map<String, dynamic> m => m,
      final Map m => Map<String, dynamic>.from(m),
      _ => const <String, dynamic>{},
    };
    final countsSoFar = countsMap.map(
      (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
    );

    return PoiMapboxStreamChunk(
      uiCategory: (json['uiCategory'] ?? '').toString(),
      chunkIndex: (json['chunkIndex'] as num?)?.toInt() ?? 0,
      pois: List.unmodifiable(pois),
      countsSoFar: Map.unmodifiable(countsSoFar),
    );
  }
}

class PoiMapboxStreamDone extends PoiMapboxStreamEvent {
  final int totalDistinct;
  final Map<String, int> countsByCategory;

  const PoiMapboxStreamDone({
    required this.totalDistinct,
    required this.countsByCategory,
  });

  factory PoiMapboxStreamDone.fromJson(Map<String, dynamic> json) {
    final raw = json['countsByCategory'];
    final Map<String, dynamic> countsMap = switch (raw) {
      final Map<String, dynamic> m => m,
      final Map m => Map<String, dynamic>.from(m),
      _ => const <String, dynamic>{},
    };
    final countsByCategory = countsMap.map(
      (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
    );
    return PoiMapboxStreamDone(
      totalDistinct: (json['totalDistinct'] as num?)?.toInt() ?? 0,
      countsByCategory: Map.unmodifiable(countsByCategory),
    );
  }
}
