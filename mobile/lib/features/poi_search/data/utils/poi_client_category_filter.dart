import '../models/poi_category_catalog.dart';

/// İstemci tarafı kategori filtresi — [CompositePoiSearchRepository] ve AR ile uyumlu.
///
/// Tüm katalog seçiliyse `null` döner (backend’e filtre gönderilmez / tüm POI’lar).
class PoiClientCategoryFilter {
  PoiClientCategoryFilter._();

  /// [PoiSearchBloc] ile aynı kural: boş liste burada `null` değil; çağıran
  /// "hiç seçim yok" (haritada POI yok) durumunu ayrı ele alır.
  static List<String>? categoriesForSearch(List<String> selected) {
    if (selected.isEmpty) return null;

    final selectedSet = selected.map((e) => e.trim().toLowerCase()).toSet();
    final allKeys =
        PoiCategoryCatalog.all.map((e) => e.key.toLowerCase()).toSet();
    if (selectedSet.length == allKeys.length &&
        selectedSet.containsAll(allKeys)) {
      return null;
    }

    return selected;
  }
}
