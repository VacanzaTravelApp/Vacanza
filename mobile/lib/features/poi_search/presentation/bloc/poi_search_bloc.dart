import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/config/poi_map_config.dart';

import '../../data/api/poi_mapbox_stream_event.dart';
import '../../data/models/area_source.dart';
import '../../data/models/poi.dart';
import '../../data/models/poi_category_catalog.dart';
import '../../data/models/selected_area.dart';
import '../../data/utils/poi_client_category_filter.dart';
import '../../data/utils/poi_stream_merge.dart';
import '../../data/repositories/poi_search_repository.dart';
import '../../data/repositories/poi_search_repository_exception.dart';
import 'poi_search_event.dart';
import 'poi_search_state.dart';

/// VACANZA-187: POI Search BLoC (events + state)
class PoiSearchBloc extends Bloc<PoiSearchEvent, PoiSearchState> {
  final PoiSearchRepository _repo;

  PoiSearchBloc({required PoiSearchRepository repo})
    : _repo = repo,
      super(PoiSearchState.initial()) {
    on<ViewportChanged>(_onViewportChanged);
    on<AreaChanged>(_onAreaChanged);
    on<AreaCleared>(_onAreaCleared);
    on<CategoryChanged>(_onCategoryChanged);
    on<SortChanged>(_onSortChanged);

    on<SearchRequested>(_onSearchRequested);
    on<LoadNextPage>(_onLoadNextPage);

    on<HidePoiMarkers>(_onHidePoiMarkers);
    on<ShowPoiMarkers>(_onShowPoiMarkers);
    on<StreamChipSuggestionConsumed>(_onStreamChipSuggestionConsumed);
  }

  /// Son gelen viewport bbox’u burada cache’liyoruz.
  BboxArea? _lastViewportBbox;

  CancelToken? _mapboxStreamCancel;
  int _mapboxStreamGen = 0;

  @override
  Future<void> close() {
    _cancelActiveMapboxStream();
    return super.close();
  }

  void _cancelActiveMapboxStream() {
    final had = _mapboxStreamCancel != null;
    _mapboxStreamCancel?.cancel();
    _mapboxStreamCancel = null;
    if (had) _mapboxStreamGen++;
  }

  void _onStreamChipSuggestionConsumed(
    StreamChipSuggestionConsumed event,
    Emitter<PoiSearchState> emit,
  ) {
    emit(state.copyWith(streamSuggestedChipKey: null));
  }

  void _onViewportChanged(ViewportChanged event, Emitter<PoiSearchState> emit) {
    if (_bboxTooLargeForSearch(event.bbox)) {
      log('[PoiSearchBloc] IGNORE viewport (bbox too large) -> zoom in');
      return;
    }

    _lastViewportBbox = event.bbox;

    if (state.areaSource == AreaSource.userSelection) {
      log('[PoiSearchBloc] IGNORE viewport (USER_SELECTION active)');
      return;
    }

    if (state.selectedArea is BboxArea) {
      final cur = state.selectedArea as BboxArea;
      if (cur == event.bbox || cur.isNearlyEqual(event.bbox)) {
        return;
      }
    }

    emit(
      state.copyWith(
        areaSource: AreaSource.viewport,
        selectedArea: event.bbox,
        page: 0,
      ),
    );

    add(const SearchRequested());
  }

  void _onAreaChanged(AreaChanged event, Emitter<PoiSearchState> emit) {
    emit(
      state.copyWith(
        areaSource: AreaSource.userSelection,
        selectedArea: event.area,
        page: 0,
      ),
    );

    add(const SearchRequested());
  }

  void _onAreaCleared(AreaCleared event, Emitter<PoiSearchState> emit) {
    _cancelActiveMapboxStream();

    final fallback = _lastViewportBbox ?? const NoArea();

    emit(
      state.copyWith(
        areaSource: AreaSource.viewport,
        selectedArea: fallback,
        page: 0,
        status: PoiSearchStatus.idle,
        errorCode: null,
        errorMessage: null,
        count: 0,
        pois: const [],
        countsByCategory: const {},
        mapboxAreaStreamLoading: false,
        streamSuggestedChipKey: null,
      ),
    );

    if (fallback.isUsable) {
      add(const SearchRequested());
    }
  }

  void _onHidePoiMarkers(HidePoiMarkers event, Emitter<PoiSearchState> emit) {
    emit(state.copyWith(hidePoiMarkers: true));
  }

  void _onShowPoiMarkers(ShowPoiMarkers event, Emitter<PoiSearchState> emit) {
    emit(state.copyWith(hidePoiMarkers: false));
    if (state.hasUsableArea) {
      add(const SearchRequested());
    }
  }

  bool _bboxTooLargeForSearch(BboxArea b) {
    final latSpan = (b.maxLat - b.minLat).abs();
    final lngSpan = (b.maxLng - b.minLng).abs();

    return latSpan > 0.15 || lngSpan > 0.15;
  }

  void _onCategoryChanged(CategoryChanged event, Emitter<PoiSearchState> emit) {
    final next = state.copyWith(
      selectedCategories: List.unmodifiable(event.categories),
      page: 0,
    );
    emit(next);

    if (next.hasUsableArea) {
      add(const SearchRequested());
    }
  }

  void _onSortChanged(SortChanged event, Emitter<PoiSearchState> emit) {
    final next = state.copyWith(sort: event.sort, page: 0);
    emit(next);
    if (next.hasUsableArea) add(const SearchRequested());
  }

  Future<void> _onSearchRequested(
    SearchRequested event,
    Emitter<PoiSearchState> emit,
  ) async {
    if (!state.hasUsableArea) return;

    if (state.selectedCategories.isEmpty) {
      _cancelActiveMapboxStream();
      emit(
        state.copyWith(
          status: PoiSearchStatus.success,
          count: 0,
          pois: const [],
          countsByCategory: const {},
          page: 0,
          errorCode: null,
          errorMessage: null,
          mapboxAreaStreamLoading: false,
          streamSuggestedChipKey: null,
        ),
      );
      return;
    }

    _cancelActiveMapboxStream();

    final page = 0;
    final limit = state.limit.clamp(1, 500);

    final categories =
        PoiClientCategoryFilter.categoriesForSearch(state.selectedCategories);

    final useMapboxStream =
        PoiMapConfig.useMapboxAreaSearch &&
        state.selectedArea is PolygonArea &&
        state.areaSource == AreaSource.userSelection;

    if (useMapboxStream) {
      await _runMapboxAreaSearchStream(
        emit: emit,
        categories: categories,
        page: page,
        limit: limit,
      );
      return;
    }

    emit(
      state.copyWith(
        status: PoiSearchStatus.loading,
        errorCode: null,
        errorMessage: null,
        page: page,
        mapboxAreaStreamLoading: false,
        streamSuggestedChipKey: null,
      ),
    );

    try {
      final res = await _repo.searchInArea(
        area: state.selectedArea,
        categories: categories,
        page: page,
        limit: limit,
        sort: state.sort,
      );

      log('[PoiSearchBloc] success: count=${res.count}, pois=${res.pois.length}');

      emit(
        state.copyWith(
          status: PoiSearchStatus.success,
          count: res.count,
          pois: res.pois,
          countsByCategory: res.countsByCategory,
        ),
      );
    } on PoiSearchRepositoryException catch (e) {
      log('[PoiSearchBloc] error: ${e.code} -> ${e.message}');
      emit(
        state.copyWith(
          status: PoiSearchStatus.error,
          errorCode: e.code,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      log('[PoiSearchBloc] unknown error: $e');
      emit(
        state.copyWith(
          status: PoiSearchStatus.error,
          errorCode: 'UNKNOWN_ERROR',
          errorMessage: 'Request failed',
        ),
      );
    }
  }

  Future<void> _runMapboxAreaSearchStream({
    required Emitter<PoiSearchState> emit,
    required List<String>? categories,
    required int page,
    required int limit,
  }) async {
    final streamGen = _mapboxStreamGen;
    final cancel = CancelToken();
    _mapboxStreamCancel = cancel;

    emit(
      state.copyWith(
        status: PoiSearchStatus.success,
        errorCode: null,
        errorMessage: null,
        page: 0,
        pois: const [],
        count: 0,
        countsByCategory: const {},
        mapboxAreaStreamLoading: true,
        streamSuggestedChipKey: null,
      ),
    );

    var merged = <Poi>[];
    String? chipSuggestion;
    var suggestedLocked = false;
    var sawDone = false;

    try {
      await for (final streamEvent in _repo.searchInAreaMapboxStream(
        area: state.selectedArea,
        categories: categories,
        page: page,
        limit: limit,
        sort: state.sort,
        cancelToken: cancel,
      )) {
        if (isClosed || streamGen != _mapboxStreamGen) return;

        if (streamEvent is PoiMapboxStreamChunk) {
          merged = PoiStreamMerge.mergeChunk(merged, streamEvent.pois);
          final counts = PoiCategoryCatalog.countsByUiKey(
            merged.map((Poi p) => p.category),
          );

          if (!suggestedLocked && streamEvent.pois.isNotEmpty) {
            final k = streamEvent.uiCategory.trim().toLowerCase();
            if (k.isNotEmpty) {
              chipSuggestion = k;
              suggestedLocked = true;
            }
          }

          emit(
            state.copyWith(
              status: PoiSearchStatus.success,
              pois: merged,
              count: merged.length,
              countsByCategory: counts,
              mapboxAreaStreamLoading: true,
              streamSuggestedChipKey: chipSuggestion,
            ),
          );
        } else if (streamEvent is PoiMapboxStreamDone) {
          sawDone = true;
          final counts = PoiCategoryCatalog.countsByUiKey(
            merged.map((Poi p) => p.category),
          );
          emit(
            state.copyWith(
              status: PoiSearchStatus.success,
              pois: merged,
              count: merged.length,
              countsByCategory: counts,
              mapboxAreaStreamLoading: false,
              streamSuggestedChipKey: chipSuggestion,
            ),
          );
        }
      }

      if (!isClosed && streamGen == _mapboxStreamGen && !sawDone) {
        emit(state.copyWith(mapboxAreaStreamLoading: false));
      }
    } on PoiSearchRepositoryException catch (e) {
      if (isClosed || streamGen != _mapboxStreamGen) return;
      log('[PoiSearchBloc] mapbox stream error: ${e.code} -> ${e.message}');
      emit(
        state.copyWith(
          status: PoiSearchStatus.error,
          errorCode: e.code,
          errorMessage: e.message,
          mapboxAreaStreamLoading: false,
        ),
      );
    } catch (e) {
      if (isClosed || streamGen != _mapboxStreamGen) return;
      log('[PoiSearchBloc] mapbox stream unknown: $e');
      emit(
        state.copyWith(
          status: PoiSearchStatus.error,
          errorCode: 'UNKNOWN_ERROR',
          errorMessage: 'Request failed',
          mapboxAreaStreamLoading: false,
        ),
      );
    } finally {
      if (_mapboxStreamCancel == cancel) {
        _mapboxStreamCancel = null;
      }
    }
  }

  Future<void> _onLoadNextPage(
    LoadNextPage event,
    Emitter<PoiSearchState> emit,
  ) async {
    // ops: şimdilik MVP dışı.
  }
}
