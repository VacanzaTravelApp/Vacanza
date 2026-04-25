import 'dart:developer';

import 'package:dio/dio.dart';

import '../api/poi_mapbox_stream_event.dart';
import '../api/poi_search_in_area_request_dto.dart';
import '../api/poi_search_in_area_response_dto.dart';
import '../models/poi.dart';
import '../models/poi_category_catalog.dart';
import '../models/selected_area.dart';
import '../utils/hybrid_poi_merge.dart';
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
      // Her zaman alan için tam veri — kategori daraltması istemcide (harita kayınca eski bbox
      // sayılarına yapışmaması ve filtre paneli sayılarının tutarlı kalması için).
      backendRes = await _backend.searchInArea(
        area: area,
        categories: null,
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

    final mergedUnfiltered = HybridPoiMerge.mergeBackendAndStyle(
      area: area,
      backendPois: backendRes.pois,
      stylePois: stylePois,
    );

    final counts = PoiCategoryCatalog.countsByUiKey(
      mergedUnfiltered.map((p) => p.category),
    );

    final filtered = _applyCategoryFilter(
      mergedUnfiltered,
      categories: categories,
    );

    return PoiSearchInAreaResponseDto(
      count: filtered.length,
      pois: filtered,
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

  /// [categories] null => tümü (Bloc "hepsi seçili" ile uyumlu).
  List<Poi> _applyCategoryFilter(
    List<Poi> pois, {
    List<String>? categories,
  }) {
    final selected = <String>{
      if (categories != null)
        for (final c in categories) c.trim().toLowerCase(),
    };

    return pois
        .where(
          (p) => PoiCategoryCatalog.passesCategoryFilter(
            rawCategory: p.category,
            selectedUiKeys: selected,
            treatEmptySelectionAsShowAll: true,
          ),
        )
        .toList();
  }

  @override
  Stream<PoiMapboxStreamEvent> searchInAreaMapboxStream({
    required SelectedArea area,
    List<String>? categories,
    int page = 0,
    int? limit,
    PoiSort? sort,
    CancelToken? cancelToken,
  }) async* {
    // Style discovery'yi backend stream ile paralel başlat.
    final styleFuture = _tryStyleDiscovery();

    PoiMapboxStreamDone? pendingDone;

    await for (final event in _backend.searchInAreaMapboxStream(
      area: area,
      categories: categories,
      page: page,
      limit: limit,
      sort: sort,
      cancelToken: cancelToken,
    )) {
      if (event is PoiMapboxStreamDone) {
        // Done'u beklet — önce style POI'lerini enjekte et.
        pendingDone = event;
      } else {
        yield event;
      }
    }

    // Backend bitti: style POI'lerini filtrele ve chunk olarak ekle.
    try {
      var stylePois = await styleFuture;
      if (stylePois.isNotEmpty) {
        if (area is PolygonArea) {
          stylePois = stylePois
              .where(
                (p) => pointInsidePolygonLatLng(
                  lat: p.latitude,
                  lng: p.longitude,
                  polygonLatLng: area.points,
                ),
              )
              .toList();
        }
        final filtered = _applyCategoryFilter(stylePois, categories: categories);
        if (filtered.isNotEmpty) {
          log('[CompositePoiSearchRepository] injecting ${filtered.length} style POIs into stream');
          yield PoiMapboxStreamChunk(
            uiCategory: '',
            chunkIndex: -1,
            pois: List.unmodifiable(filtered),
            countsSoFar: const {},
          );
        }
      }
    } catch (e, st) {
      log('[CompositePoiSearchRepository] stream style discovery failed: $e\n$st');
    }

    if (pendingDone != null) yield pendingDone;
  }
}
