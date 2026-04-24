import 'package:dio/dio.dart';

import '../api/poi_mapbox_stream_event.dart';
import '../api/poi_search_in_area_request_dto.dart';
import '../api/poi_search_in_area_response_dto.dart';
import '../models/selected_area.dart';

/// POI Search repository contract (UI/Bloc Dio görmez)
abstract class PoiSearchRepository {
  Future<PoiSearchInAreaResponseDto> searchInArea({
    required SelectedArea area,
    List<String>? categories,
    int page,
    int? limit,
    PoiSort? sort,
  });

  /// Mapbox tiled progressive arama (polygon + `mapboxAreaSearch`). Stil tabanlı POI birleşmez.
  Stream<PoiMapboxStreamEvent> searchInAreaMapboxStream({
    required SelectedArea area,
    List<String>? categories,
    int page = 0,
    int? limit,
    PoiSort? sort,
    CancelToken? cancelToken,
  });
}