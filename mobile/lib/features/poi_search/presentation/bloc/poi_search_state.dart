import 'package:equatable/equatable.dart';

import '../../data/api/poi_search_in_area_request_dto.dart';
import '../../data/models/area_source.dart';
import '../../data/models/poi.dart';
import '../../data/models/poi_categories.dart';
import '../../data/models/selected_area.dart';

// ✅ bunu senin koyduğun dosya yoluna göre import et
// örn: import '../../domain/poi_categories.dart';

enum PoiSearchStatus { idle, loading, success, error }

/// POI search state (VACANZA-187)
class PoiSearchState extends Equatable {
  final AreaSource areaSource;
  final SelectedArea selectedArea;

  final List<String> selectedCategories;
  final PoiSort? sort;

  final int page;
  final int limit;

  final PoiSearchStatus status;
  final String? errorCode;
  final String? errorMessage;

  final int count;
  final List<Poi> pois;
  final Map<String, int> countsByCategory;

  const PoiSearchState({
    required this.areaSource,
    required this.selectedArea,
    required this.selectedCategories,
    required this.sort,
    required this.page,
    required this.limit,
    required this.status,
    required this.errorCode,
    required this.errorMessage,
    required this.count,
    required this.pois,
    required this.countsByCategory,
  });

  /// ✅ default seçili kategoriler PM'e göre:
  /// restaurants, cafe, museum, monuments, parks
  factory PoiSearchState.initial() => PoiSearchState(
    areaSource: AreaSource.viewport,
    selectedArea: NoArea(),
    selectedCategories: PoiCategories.defaults,
    sort: PoiSort.distanceToCenter,
    page: 0,
    limit: 200,
    status: PoiSearchStatus.idle,
    errorCode: null,
    errorMessage: null,
    count: 0,
    pois: const [],
    countsByCategory: const {},
  );

  bool get isLoading => status == PoiSearchStatus.loading;
  bool get hasUsableArea => selectedArea.isUsable;

  PoiSearchState copyWith({
    AreaSource? areaSource,
    SelectedArea? selectedArea,
    List<String>? selectedCategories,
    PoiSort? sort,
    int? page,
    int? limit,
    PoiSearchStatus? status,
    String? errorCode,
    String? errorMessage,
    int? count,
    List<Poi>? pois,
    Map<String, int>? countsByCategory,
  }) {
    return PoiSearchState(
      areaSource: areaSource ?? this.areaSource,
      selectedArea: selectedArea ?? this.selectedArea,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      sort: sort ?? this.sort,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      status: status ?? this.status,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
      count: count ?? this.count,
      pois: pois ?? this.pois,
      countsByCategory: countsByCategory ?? this.countsByCategory,
    );
  }

  @override
  List<Object?> get props => [
    areaSource,
    selectedArea,
    selectedCategories,
    sort,
    page,
    limit,
    status,
    errorCode,
    errorMessage,
    count,
    pois,
    countsByCategory,
  ];
}