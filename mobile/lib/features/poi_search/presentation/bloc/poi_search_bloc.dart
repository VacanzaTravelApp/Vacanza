import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/api/poi_search_in_area_request_dto.dart';
import '../../data/api/poi_search_in_area_response_dto.dart';
import '../../data/models/selected_area.dart';
import '../../data/repositories/poi_search_repository.dart';
import '../../data/repositories/poi_search_repository_exception.dart';

sealed class PoiSearchState {
  const PoiSearchState();
}

class PoiSearchIdle extends PoiSearchState {
  const PoiSearchIdle();
}

class PoiSearchLoading extends PoiSearchState {
  const PoiSearchLoading();
}

class PoiSearchSuccess extends PoiSearchState {
  final PoiSearchInAreaResponseDto data;
  const PoiSearchSuccess(this.data);
}

class PoiSearchError extends PoiSearchState {
  final String code;
  final String message;
  const PoiSearchError({required this.code, required this.message});
}

class PoiSearchBloc extends Cubit<PoiSearchState> {
  final PoiSearchRepository _repo;

  PoiSearchBloc({required PoiSearchRepository repo})
      : _repo = repo,
        super(const PoiSearchIdle());

  Future<void> fetchForArea({
    required SelectedArea area,
    List<String>? categories,
    int page = 0,
    int? limit,
    PoiSort? sort,
  }) async {
    if (!area.isUsable) return;

    final int effectiveLimit = (limit ?? 200).clamp(1, 500).toInt();

    emit(const PoiSearchLoading());

    try {
      final res = await _repo.searchInArea(
        area: area,
        categories: categories, // repo normalize eder (lowercase + uniq)
        page: page,
        limit: effectiveLimit,
        sort: sort,
      );

      log('[PoiSearchBloc] success: count=${res.count}, pois=${res.pois.length}');
      emit(PoiSearchSuccess(res));
    } on PoiSearchRepositoryException catch (e) {
      log('[PoiSearchBloc] error: ${e.code} -> ${e.message}');
      emit(PoiSearchError(code: e.code, message: e.message));
    } catch (e) {
      log('[PoiSearchBloc] unknown error: $e');
      emit(const PoiSearchError(code: 'UNKNOWN_ERROR', message: 'Request failed'));
    }
  }
}