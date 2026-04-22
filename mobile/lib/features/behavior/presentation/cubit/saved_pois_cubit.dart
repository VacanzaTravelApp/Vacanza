import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/api/feedback_api_client.dart';
import '../../domain/feedback_poi_ref.dart';
import '../../domain/poi_feedback_utils.dart';
import '../../domain/saved_poi.dart';
import 'favorite_poi_cubit.dart';

class SavedPoisState extends Equatable {
  const SavedPoisState({
    this.items = const [],
    this.isLoading = false,
  });

  final List<SavedPoi> items;
  final bool isLoading;

  SavedPoisState copyWith({
    List<SavedPoi>? items,
    bool? isLoading,
  }) => SavedPoisState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
  );

  @override
  List<Object?> get props => [items, isLoading];
}

class SavedPoisCubit extends Cubit<SavedPoisState> {
  SavedPoisCubit({
    required FeedbackApiClient api,
    required FavoritePoiCubit favoritePoiCubit,
  }) : _api = api,
       _favoritePoiCubit = favoritePoiCubit,
       super(const SavedPoisState());

  final FeedbackApiClient _api;
  final FavoritePoiCubit _favoritePoiCubit;

  Future<void> refresh() async {
    if (state.isLoading) return;
    emit(state.copyWith(isLoading: true));
    try {
      final items = await _api.fetchSavedPois();
      emit(SavedPoisState(items: items, isLoading: false));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> remove(SavedPoi poi) async {
    final lat = poi.latitude;
    final lon = poi.longitude;
    if (lat == null || lon == null) return;

    final ref = FeedbackPoiRef(
      name: poi.name,
      category: poi.category ?? '',
      latitude: lat,
      longitude: lon,
      foursquareId: null,
      mapboxId: null,
    );

    final body = buildPoiFeedbackEventBody(eventType: 'THUMBS_DOWN', p: ref);
    try {
      await _api.postPoiFeedbackEvent(body);
    } catch (_) {
      return;
    }

    await refresh();
    await _favoritePoiCubit.refreshAffinity();
  }
}

