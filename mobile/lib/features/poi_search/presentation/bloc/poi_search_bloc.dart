import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/area_source.dart';
import '../../data/models/selected_area.dart';
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
    on<LoadNextPage>(_onLoadNextPage); // opsiyonel
  }

  /// Son gelen viewport bbox’u burada cache’liyoruz.
  /// (USER_SELECTION aktifken bile güncellenir)
  BboxArea? _lastViewportBbox;

  void _onViewportChanged(ViewportChanged event, Emitter<PoiSearchState> emit) {
    // ✅ Çok zoom-out olunca request atma
    if (_bboxTooLargeForSearch(event.bbox)) {
      log('[PoiSearchBloc] IGNORE viewport (bbox too large) -> zoom in');
      return;
    }

    // ✅ Her zaman cache’le (AreaCleared fallback için)
    _lastViewportBbox = event.bbox;

    // ✅ User selection aktifse viewport update’leri ignore
    if (state.areaSource == AreaSource.userSelection) {
      log('[PoiSearchBloc] IGNORE viewport (USER_SELECTION active)');
      return;
    }

    // ✅ Aynı bbox geldiyse spam request atma
    if (state.selectedArea is BboxArea && state.selectedArea == event.bbox) {
      return;
    }

    emit(
      state.copyWith(
        areaSource: AreaSource.viewport,
        selectedArea: event.bbox,
        page: 0,
      ),
    );

    // ✅ User selection yokken viewport bbox ile otomatik search
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
    // ✅ Viewport moduna dön; map hareket etmese bile son bbox varsa direkt ona döneriz.
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
      ),
    );

    // ✅ Eğer fallback usable ise hemen tekrar search et
    if (fallback.isUsable) {
      add(const SearchRequested());
    }
  }

  bool _bboxTooLargeForSearch(BboxArea b) {
    final latSpan = (b.maxLat - b.minLat).abs();
    final lngSpan = (b.maxLng - b.minLng).abs();

    // ✅ agresif threshold (senin istediğin): 0.15
    return latSpan > 0.15 || lngSpan > 0.15;
  }

  void _onCategoryChanged(CategoryChanged event, Emitter<PoiSearchState> emit) {
    emit(
      state.copyWith(
        selectedCategories: List.unmodifiable(event.categories),
        page: 0,
      ),
    );

    if (state.hasUsableArea) {
      add(const SearchRequested());
    }
  }

  void _onSortChanged(SortChanged event, Emitter<PoiSearchState> emit) {
    emit(state.copyWith(sort: event.sort, page: 0));
    if (state.hasUsableArea) add(const SearchRequested());
  }

  Future<void> _onSearchRequested(
      SearchRequested event,
      Emitter<PoiSearchState> emit,
      ) async {
    if (!state.hasUsableArea) return;

    final page = 0;
    final limit = state.limit.clamp(1, 500);

    emit(
      state.copyWith(
        status: PoiSearchStatus.loading,
        errorCode: null,
        errorMessage: null,
        page: page,
      ),
    );

    try {
      final res = await _repo.searchInArea(
        area: state.selectedArea,
        categories: state.selectedCategories.isEmpty ? null : state.selectedCategories,
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

  Future<void> _onLoadNextPage(LoadNextPage event, Emitter<PoiSearchState> emit) async {
    // ops: şimdilik MVP dışı.
  }
}