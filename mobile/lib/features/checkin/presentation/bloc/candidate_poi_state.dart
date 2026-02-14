import '../../../poi_search/data/models/selected_area.dart';

/// Immutable state for [CandidatePoiCubit].
///
/// [viewport] — current map viewport bbox (null until first update).
/// [candidatePoiIds] — POI IDs whose (lat, lng) fall inside [viewport].
class CandidatePoiState {
  final BboxArea? viewport;
  final List<String> candidatePoiIds;

  const CandidatePoiState({this.viewport, this.candidatePoiIds = const []});

  CandidatePoiState copyWith({BboxArea? viewport, List<String>? candidatePoiIds}) {
    return CandidatePoiState(
      viewport: viewport ?? this.viewport,
      candidatePoiIds: candidatePoiIds ?? this.candidatePoiIds,
    );
  }

  @override
  String toString() =>
      'CandidatePoiState(viewport: ${viewport != null ? "set" : "null"}, '
      'candidates: ${candidatePoiIds.length})';
}
