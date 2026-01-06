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

  void _onViewportChanged(ViewportChanged event, Emitter<PoiSearchState> emit) {
    // ✅ User selection aktifse viewport update’leri ignore
    if (state.areaSource == AreaSource.userSelection) {
      log('[PoiSearchBloc] IGNORE viewport (USER_SELECTION active)');
      return;
    }

    // Aynı bbox geldiyse spam request atma
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
    // Viewport moduna dön; bbox zaten MapCanvas’tan tekrar gelecek
    emit(
      state.copyWith(
        areaSource: AreaSource.viewport,
        selectedArea: const NoArea(),
        page: 0,
        status: PoiSearchStatus.idle,
        errorCode: null,
        errorMessage: null,
        count: 0,
        pois: const [],
        countsByCategory: const {},
      ),
    );
  }

  void _onCategoryChanged(CategoryChanged event, Emitter<PoiSearchState> emit) {
    // Repository normalize ediyor (lowercase + uniq), burada sadece state’i tutuyoruz.
    emit(state.copyWith(selectedCategories: List.unmodifiable(event.categories), page: 0));

    // ✅ Category değişince aynı aktif area ile yeniden request
    if (state.hasUsableArea) {
      add(const SearchRequested());
    }
  }

  void _onSortChanged(SortChanged event, Emitter<PoiSearchState> emit) {
    emit(state.copyWith(sort: event.sort, page: 0));
    if (state.hasUsableArea) add(const SearchRequested());
  }

  Future<void> _onSearchRequested(SearchRequested event, Emitter<PoiSearchState> emit) async {
    if (!state.hasUsableArea) return;

    // MVP: pagination yoksa page=0
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
    // ops: şimdilik MVP dışı. İstersen sonra açarız.
  }
}