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
}