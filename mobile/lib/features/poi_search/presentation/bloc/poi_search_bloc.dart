import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/api/poi_search_api_client.dart';
import '../../data/api/poi_search_in_area_request_dto.dart';
import '../../data/api/poi_search_in_area_response_dto.dart';
import '../../data/models/selected_area.dart';

/// POI Search state base type
sealed class PoiSearchState {
  const PoiSearchState();
}

/// Initial / idle state (no request in-flight)
class PoiSearchIdle extends PoiSearchState {
  const PoiSearchIdle();
}

/// Request in-flight
class PoiSearchLoading extends PoiSearchState {
  const PoiSearchLoading();
}

/// Request succeeded
class PoiSearchSuccess extends PoiSearchState {
  final PoiSearchInAreaResponseDto data;
  const PoiSearchSuccess(this.data);
}

/// Request failed (known API error)
class PoiSearchError extends PoiSearchState {
  final String code;
  final String message;
  const PoiSearchError({required this.code, required this.message});
}

class PoiSearchBloc extends Cubit<PoiSearchState> {
  final PoiSearchApiClient _api;

  PoiSearchBloc({required PoiSearchApiClient api})
      : _api = api,
        super(const PoiSearchIdle());

  /// Fetch POIs for the currently active area (viewport bbox OR user polygon)
  ///
  /// - `categories`: optional filter. If null/empty => send null (means "no filter").
  /// - `limit`: FE default is 200, FE max is 500 (enforced here).
  /// - `sort`: optional. Supported: RATING_DESC, DISTANCE_TO_CENTER.
  Future<void> fetchForArea({
    required SelectedArea area,
    List<String>? categories,
    int page = 0,
    int? limit,
    PoiSort? sort,
  }) async {
    // If area isn't usable (e.g., NoArea), skip the call.
    if (!area.isUsable) return;

    // 1) Normalize categories (case-insensitive safety)
    // 2) If it ends up empty -> send null (backend: "no filter")
    final normalizedCategoriesRaw = (categories == null || categories.isEmpty)
        ? null
        : categories
        .map(_normalizeCategory)
        .where((c) => c.isNotEmpty)
        .toList(growable: false);

    final normalizedCategories =
    (normalizedCategoriesRaw == null || normalizedCategoriesRaw.isEmpty)
        ? null
        : normalizedCategoriesRaw;

    // FE rules: default 200, max 500
    final int effectiveLimit = (limit ?? 200).clamp(1, 500).toInt();

    emit(const PoiSearchLoading());

    try {
      final res = await _api.searchInArea(
        area: area,
        categories: normalizedCategories, // ✅ FIX: actually send them
        page: page,
        limit: effectiveLimit,
        sort: sort,
      );

      log('[PoiSearchBloc] success: count=${res.count}, pois=${res.pois.length}');
      emit(PoiSearchSuccess(res));
    } on PoiSearchApiException catch (e) {
      log('[PoiSearchBloc] error: ${e.code} -> ${e.message}');
      emit(PoiSearchError(code: e.code, message: e.message));
    } catch (e) {
      log('[PoiSearchBloc] unknown error: $e');
      emit(const PoiSearchError(code: 'UNKNOWN_ERROR', message: 'Request failed'));
    }
  }

  /// Normalizes a category string for backend matching (basic strategy).
  /// Example:
  /// - "museum" -> "Museum"
  /// - "RESTAURANT" -> "Restaurant"
  String _normalizeCategory(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '';

   // final lower = s.toLowerCase();
   // return lower[0].toUpperCase() + lower.substring(1);
    return s.toLowerCase();
  }
}