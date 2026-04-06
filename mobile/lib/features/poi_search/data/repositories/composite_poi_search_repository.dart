import 'dart:developer';

import '../api/poi_search_in_area_request_dto.dart';
import '../api/poi_search_in_area_response_dto.dart';
import '../models/poi.dart';
import '../models/poi_category_catalog.dart';
import '../models/selected_area.dart';
import '../utils/polygon_contains.dart';
import '../services/mapbox_style_poi_discovery.dart';
import '../services/style_poi_discovery_binding.dart';
import 'poi_search_repository.dart';
import 'poi_search_repository_exception.dart';

/// Backend [search-in-area] + Mapbox stil [queryRenderedFeatures] (web MapPage hibrit akışı).
class CompositePoiSearchRepository implements PoiSearchRepository {
  CompositePoiSearchRepository({
    required PoiSearchRepository backend,
    required StylePoiDiscoveryBinding styleBinding,
  })  : _backend = backend,
        _styleBinding = styleBinding;

  final PoiSearchRepository _backend;
  final StylePoiDiscoveryBinding _styleBinding;

  @override
  Future<PoiSearchInAreaResponseDto> searchInArea({
    required SelectedArea area,
    List<String>? categories,
    int page = 0,
    int? limit,
    PoiSort? sort,
  }) async {
    PoiSearchInAreaResponseDto backendRes;
    try {
      backendRes = await _backend.searchInArea(
        area: area,
        categories: categories,
        page: page,
        limit: limit,
        sort: sort,
      );
    } on PoiSearchRepositoryException catch (e) {
      log(
        '[CompositePoiSearchRepository] backend failed (${e.code}), '
        'falling back to Mapbox style POIs only: ${e.message}',
      );
      backendRes = const PoiSearchInAreaResponseDto(
        count: 0,
        pois: [],
        countsByCategory: {},
      );
    } catch (e, st) {
      log(
        '[CompositePoiSearchRepository] backend unexpected error, '
        'style-only fallback: $e\n$st',
      );
      backendRes = const PoiSearchInAreaResponseDto(
        count: 0,
        pois: [],
        countsByCategory: {},
      );
    }

    var stylePois = const <Poi>[];
    try {
      stylePois = await _tryStyleDiscovery();
    } catch (e, st) {
      log('[CompositePoiSearchRepository] style discovery failed: $e\n$st');
    }

    final merged = _mergeAndFilter(
      area: area,
      backendPois: backendRes.pois,
      stylePois: stylePois,
      categories: categories,
    );

    final counts = PoiCategoryCatalog.countsByUiKey(
      merged.map((p) => p.category),
    );

    return PoiSearchInAreaResponseDto(
      count: merged.length,
      pois: merged,
      countsByCategory: counts,
    );
  }

  Future<List<Poi>> _tryStyleDiscovery() async {
    final map = _styleBinding.map;
    if (map == null) return const [];

    return MapboxStylePoiDiscovery.discoverVisiblePois(
      map: map,
      logicalViewportSize: _styleBinding.viewportSize,
    );
  }

  /// Web `pois` useMemo: backend + Mapbox, 4 ondalık dedupe, kategori + polygon filtresi.
  List<Poi> _mergeAndFilter({
    required SelectedArea area,
    required List<Poi> backendPois,
    required List<Poi> stylePois,
    List<String>? categories,
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
      '[CompositePoiSearchRepository] merged=${all.length} '
      '(backend=${backendPois.length} style=${stylePois.length})',
    );

    final selected = <String>{
      if (categories != null)
        for (final c in categories) c.trim().toLowerCase(),
    };

    // null veya boş => backend ile aynı: filtre kısıtı yok (tüm eşleşenler)
    var filtered = all
        .where(
          (p) => PoiCategoryCatalog.passesCategoryFilter(
            rawCategory: p.category,
            selectedUiKeys: selected,
            treatEmptySelectionAsShowAll: true,
          ),
        )
        .toList();

    if (area is PolygonArea) {
      filtered = filtered
          .where(
            (p) => pointInsidePolygonLatLng(
              lat: p.latitude,
              lng: p.longitude,
              polygonLatLng: area.points,
            ),
          )
          .toList();
    }

    return filtered;
  }

  static bool _poiInBbox(Poi p, BboxArea b) {
    return p.latitude >= b.minLat &&
        p.latitude <= b.maxLat &&
        p.longitude >= b.minLng &&
        p.longitude <= b.maxLng;
  }
}
