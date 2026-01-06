import 'package:equatable/equatable.dart';

import '../../data/api/poi_search_in_area_request_dto.dart';
import '../../data/models/selected_area.dart';

/// POI search flow events (VACANZA-187)
sealed class PoiSearchEvent extends Equatable {
  const PoiSearchEvent();

  @override
  List<Object?> get props => [];
}

/// Viewport bbox güncellendi (map hareket etti).
/// USER_SELECTION aktifse BLoC bunu ignore edecek.
class ViewportChanged extends PoiSearchEvent {
  final BboxArea bbox;

  const ViewportChanged(this.bbox);

  @override
  List<Object?> get props => [bbox];
}

/// Kullanıcı polygon seçti (user selection).
class AreaChanged extends PoiSearchEvent {
  final SelectedArea area;

  const AreaChanged(this.area);

  @override
  List<Object?> get props => [area];
}

/// Kullanıcı selection temizledi (viewport moduna geri).
class AreaCleared extends PoiSearchEvent {
  const AreaCleared();
}

/// Kategori filtresi değişti.
class CategoryChanged extends PoiSearchEvent {
  final List<String> categories;

  const CategoryChanged(this.categories);

  @override
  List<Object?> get props => [categories];
}

/// Manuel search tetik (ör: buton).
class SearchRequested extends PoiSearchEvent {
  const SearchRequested();
}

/// Opsiyonel: MVP dışı pagination.
class LoadNextPage extends PoiSearchEvent {
  const LoadNextPage();
}

/// Opsiyonel: sort değişimi (şimdilik gerekmez ama hazır dursun).
class SortChanged extends PoiSearchEvent {
  final PoiSort? sort;

  const SortChanged(this.sort);

  @override
  List<Object?> get props => [sort];
}