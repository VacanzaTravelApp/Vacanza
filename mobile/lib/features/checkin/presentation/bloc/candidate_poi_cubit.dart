import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../poi_search/data/models/poi.dart';
import '../../../poi_search/data/models/selected_area.dart';
import 'candidate_poi_state.dart';

/// Maintains an in-memory list of POI IDs visible in the current map viewport.
///
/// Fed by two sources (via BlocListeners in HomeMapScreen):
/// 1. [updatePois] — called when PoiSearchBloc emits a new POI list.
/// 2. [updateViewport] — called when AreaQueryBloc emits a new viewport bbox.
///
/// MOB-3 will read [state.candidatePoiIds] for the auto check-in flow.
class CandidatePoiCubit extends Cubit<CandidatePoiState> {
  CandidatePoiCubit() : super(const CandidatePoiState());

  /// All loaded POIs (from PoiSearchBloc). Kept in memory for re-filtering
  /// whenever the viewport changes.
  List<Poi> _allPois = [];

  /// Called when PoiSearchBloc emits a new POI list.
  void updatePois(List<Poi> pois) {
    _allPois = pois;
    log('[CandidatePoiCubit] poisUpdated totalPois=${pois.length}');
    _refilter();
  }

  /// Called when AreaQueryBloc emits a new viewport bbox.
  void updateViewport(BboxArea bbox) {
    log('[CandidatePoiCubit] viewportUpdated');
    emit(state.copyWith(viewport: bbox));
    _refilter();
  }

  /// Filters [_allPois] against the current viewport bbox and emits
  /// the resulting candidate POI IDs.
  void _refilter() {
    final bbox = state.viewport;

    if (bbox == null) {
      log('[CandidatePoiCubit] bbox=null candidates=0 sample=[]');
      emit(state.copyWith(candidatePoiIds: const []));
      return;
    }

    // Normalize bbox bounds (BboxArea factory already normalizes, but guard
    // against any edge case where values arrive un-normalized).
    final minLat = math.min(bbox.minLat, bbox.maxLat);
    final maxLat = math.max(bbox.minLat, bbox.maxLat);
    final minLng = math.min(bbox.minLng, bbox.maxLng);
    final maxLng = math.max(bbox.minLng, bbox.maxLng);

    // TODO(anti-meridian): This simple range check breaks if the viewport
    // crosses the ±180° longitude line. Not handling for now — Vacanza's
    // target regions (Europe/Turkey) don't cross the anti-meridian.

    final candidates = <String>[];
    for (final poi in _allPois) {
      if (!poi.isEligibleForBackendCheckin) continue;
      if (poi.latitude >= minLat &&
          poi.latitude <= maxLat &&
          poi.longitude >= minLng &&
          poi.longitude <= maxLng) {
        candidates.add(poi.poiId);
      }
    }

    final sample = candidates.take(5).toList();
    log('[CandidatePoiCubit] '
        'bbox=$minLat,$minLng,$maxLat,$maxLng '
        'candidates=${candidates.length} '
        'sample=$sample');

    // Log first 3 candidates with full details for manual emulator testing
    final samplePois = _allPois
        .where((p) => candidates.contains(p.poiId))
        .take(3);
    for (final p in samplePois) {
      log('[CandidatePoiCubit] samplePoi '
          'id=${p.poiId} name=${p.name} '
          'lat=${p.latitude} lng=${p.longitude}');
    }

    emit(state.copyWith(candidatePoiIds: candidates));
  }
}
