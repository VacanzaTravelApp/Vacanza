import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/poi_search/data/models/poi_category_catalog.dart';

void main() {
  group('PoiCategoryCatalog', () {
    test('restaurant aliases map to restaurant ui key', () {
      expect(
        PoiCategoryCatalog.poiCategoryForRaw('catering.restaurant')?.key,
        'restaurant',
      );
      expect(
        PoiCategoryCatalog.poiCategoryForRaw('fast_food')?.key,
        'restaurant',
      );
    });

    test('park vs parks both map to park', () {
      expect(PoiCategoryCatalog.poiCategoryForRaw('park')?.key, 'park');
      expect(PoiCategoryCatalog.poiCategoryForRaw('parks')?.key, 'park');
    });

    test('Mapbox hyphenated tokens normalize to underscore aliases', () {
      expect(PoiCategoryCatalog.poiCategoryForRaw('rail-station')?.key, 'transport');
      expect(PoiCategoryCatalog.poiCategoryForRaw('fast-food')?.key, 'restaurant');
      expect(PoiCategoryCatalog.poiCategoryForRaw('coffee shop')?.key, 'cafe');
    });

    test('first matching category wins (order matters)', () {
      expect(PoiCategoryCatalog.poiCategoryForRaw('museum')?.key, 'museum');
    });

    test('unknown raw category returns null for icon mapping', () {
      expect(PoiCategoryCatalog.poiCategoryForRaw('totally_unknown_xyz'), null);
    });

    test('passesCategoryFilter: unmapped always passes', () {
      expect(
        PoiCategoryCatalog.passesCategoryFilter(
          rawCategory: 'unknown_type',
          selectedUiKeys: {'restaurant'},
          treatEmptySelectionAsShowAll: false,
        ),
        true,
      );
    });

    test('passesCategoryFilter: empty selection show all', () {
      expect(
        PoiCategoryCatalog.passesCategoryFilter(
          rawCategory: 'restaurant',
          selectedUiKeys: {},
          treatEmptySelectionAsShowAll: true,
        ),
        true,
      );
    });

    test('safePoiTitle uses label for unnamed', () {
      expect(
        PoiCategoryCatalog.safePoiTitle(
          name: 'unnamed',
          rawCategory: 'cafe',
        ),
        'Cafes',
      );
    });

    test('defaultSelectedCategoryKeys includes 11 web keys', () {
      expect(PoiCategoryCatalog.defaultSelectedCategoryKeys.length, 11);
      expect(PoiCategoryCatalog.defaultSelectedCategoryKeys, contains('park'));
      expect(PoiCategoryCatalog.defaultSelectedCategoryKeys, contains('others'));
    });
  });
}
