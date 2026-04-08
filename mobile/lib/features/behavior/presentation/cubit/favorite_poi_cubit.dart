import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/api/feedback_api_client.dart';
import '../../domain/feedback_poi_ref.dart';
import '../../domain/poi_feedback_utils.dart';

class FavoritePoiState extends Equatable {
  const FavoritePoiState({
    this.poiScores = const {},
    this.categoryScores = const {},
    this.affinityLoading = false,
  });

  final Map<String, double> poiScores;
  final Map<String, double> categoryScores;
  final bool affinityLoading;

  FavoritePoiState copyWith({
    Map<String, double>? poiScores,
    Map<String, double>? categoryScores,
    bool? affinityLoading,
  }) =>
      FavoritePoiState(
        poiScores: poiScores ?? this.poiScores,
        categoryScores: categoryScores ?? this.categoryScores,
        affinityLoading: affinityLoading ?? this.affinityLoading,
      );

  @override
  List<Object?> get props => [poiScores, categoryScores, affinityLoading];
}

enum FavoriteToggleOutcome { added, removed, failed }

/// Map POI “favorite” = web [toggleMapPoiFavorite]: thumbs via `/api/feedback/poi-events` + affinity hydration.
class FavoritePoiCubit extends Cubit<FavoritePoiState> {
  FavoritePoiCubit(this._api) : super(const FavoritePoiState()) {
    refreshAffinity();
  }

  final FeedbackApiClient _api;

  bool isFavored(FeedbackPoiRef p) =>
      deriveMapPoiFavorited(state.poiScores, p);

  Future<void> refreshAffinity() async {
    emit(state.copyWith(affinityLoading: true));
    try {
      final maps = await _api.fetchAffinity();
      emit(
        FavoritePoiState(
          poiScores: Map<String, double>.from(maps['poiScores'] ?? {}),
          categoryScores: Map<String, double>.from(maps['categoryScores'] ?? {}),
          affinityLoading: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(affinityLoading: false));
    }
  }

  /// Web: favored ? THUMBS_DOWN : THUMBS_UP
  Future<FavoriteToggleOutcome> toggle(FeedbackPoiRef p) async {
    if (!p.hasValidCoordinates) return FavoriteToggleOutcome.failed;

    final favored = isFavored(p);
    final eventType = favored ? 'THUMBS_DOWN' : 'THUMBS_UP';
    final body = buildPoiFeedbackEventBody(eventType: eventType, p: p);

    try {
      await _api.postPoiFeedbackEvent(body);
    } catch (_) {
      return FavoriteToggleOutcome.failed;
    }

    await refreshAffinity();
    return favored ? FavoriteToggleOutcome.removed : FavoriteToggleOutcome.added;
  }
}
