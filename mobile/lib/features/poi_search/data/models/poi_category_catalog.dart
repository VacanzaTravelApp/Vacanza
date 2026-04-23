import 'package:flutter/material.dart';

/// Web [MapPage.jsx] `UI_CATEGORIES` ile aynı sıra ve alias mantığı.
/// `poiIconByCategory`: ilk eşleşen kategori kazanır.
class PoiCategoryDefinition {
  const PoiCategoryDefinition({
    required this.key,
    required this.label,
    required this.aliases,
    this.geo,
    required this.ringColor,
    required this.fillColor,
    required this.markerAssetKey,
    this.iconData,
  });

  final String key;
  final String label;
  final List<String> aliases;
  final String? geo;

  /// Marker / filter accent (web `ring`)
  final Color ringColor;

  /// Pin fill (web `fill` — ARGB)
  final Color fillColor;

  /// Eski PNG asset anahtarı; harita pinleri artık runtime’da bitmap üretilir.
  final String markerAssetKey;

  final IconData? iconData;
}

class PoiCategoryCatalog {
  PoiCategoryCatalog._();

  static const List<PoiCategoryDefinition> all = <PoiCategoryDefinition>[
    PoiCategoryDefinition(
      key: 'restaurant',
      label: 'Restaurants',
      geo: 'catering.restaurant',
      ringColor: Color(0xFFFF6B6B),
      fillColor: Color(0xFFFF6B6B),
      markerAssetKey: 'restaurant',
      iconData: Icons.restaurant_rounded,
      aliases: <String>[
        'restaurant',
        'restaurants',
        'catering.restaurant',
        'fast_food',
        'food_court',
        'pizza_restaurant',
        'mexican_restaurant',
        'indian_restaurant',
        'asian_restaurant',
        'burger_restaurant',
        'diner_restaurant',
        'noodle_restaurant',
        'sushi_restaurant',
        'buffet_restaurant',
        'ramen_restaurant',
        'tapas_restaurant',
        'steakhouse',
        'turkish_restaurant',
        'japanese_restaurant',
        'chinese_restaurant',
        'seafood_restaurant',
        'italian_restaurant',
        'hawaiian_restaurant',
        'korean_barbeque_restaurant',
        'portuguese_restaurant',
        'latin_american_restaurant',
        'vietnamese_restaurant',
        'french_restaurant',
        'african_restaurant',
        'brazilian_restaurant',
        'filipino_restaurant',
        'german_restaurant',
        'carribean_restaurant',
        'middle_eastern_restaurant',
        'mediterranean_restaurant',
        'creole_restaurant',
        'peruvian_restaurant',
        'wings_joint',
        'hot_dog_stand',
        'food_truck',
        'food',
        'food_and_drink',
        'deli',
      ],
    ),
    PoiCategoryDefinition(
      key: 'cafe',
      label: 'Cafes',
      geo: 'catering.cafe',
      ringColor: Color(0xFFFFB347),
      fillColor: Color(0xFFFFB347),
      markerAssetKey: 'cafe',
      iconData: Icons.local_cafe_rounded,
      aliases: <String>[
        'cafe',
        'cafes',
        'catering.cafe',
        'coffee',
        'coffee_shop',
        'teahouse',
        'bakery',
        'dessert_shop',
        'ice_cream',
        'confectionery',
        'juice_bar',
        'bubble_tea',
        'donut_shop',
        'bagel_shop',
        'frozen_yogurt_shop',
        'waffle_shop',
        'turkish_coffeehouse',
        'coffee_roaster',
        'snack_bar',
        'tea_house',
      ],
    ),
    PoiCategoryDefinition(
      key: 'museum',
      label: 'Museums & Arts',
      geo: 'tourism.attraction.museum',
      ringColor: Color(0xFF00B4D8),
      fillColor: Color(0xFF00B4D8),
      markerAssetKey: 'museum',
      iconData: Icons.museum_rounded,
      aliases: <String>[
        'museum',
        'museums',
        'tourism.attraction.museum',
        'planetarium',
        'aquarium',
        'art_gallery',
        'zoo',
        'zoo_exhibit',
        'exhibit',
      ],
    ),
    PoiCategoryDefinition(
      key: 'monuments',
      label: 'Culture',
      ringColor: Color(0xFF4338CA),
      fillColor: Color(0xFF6366F1),
      markerAssetKey: 'monuments',
      iconData: Icons.account_balance_rounded,
      aliases: <String>[
        'monument',
        'monuments',
        'memorial',
        'castle',
        'fort',
        'place_of_worship',
        'tomb',
        'theatre',
        'gallery',
        'historic_site',
        'public_artwork',
        'outdoor_sculpture',
        'concert_hall',
        'music_venue',
        'arts_center',
        'studio',
        'movie_theater',
        'cinema',
        'theater',
        'opera_house',
        'religious_christian',
        'religious_muslim',
        'religious_jewish',
        'religious_buddhist',
      ],
    ),
    PoiCategoryDefinition(
      key: 'park',
      label: 'Parks/Nature',
      ringColor: Color(0xFF15803D),
      fillColor: Color(0xFF22C55E),
      markerAssetKey: 'park',
      iconData: Icons.park_rounded,
      aliases: <String>[
        'park',
        'parks',
        'garden',
        'forest',
        'nature_reserve',
        'wood',
        'leisure.park',
        'recreation_ground',
        'national_park',
        'playground',
        'dog_park',
        'picnic_shelter',
        'botanical_garden',
        'natural',
      ],
    ),
    PoiCategoryDefinition(
      key: 'attraction',
      label: 'Attractions',
      ringColor: Color(0xFF7E22CE),
      fillColor: Color(0xFFA855F7),
      markerAssetKey: 'attraction',
      iconData: Icons.explore_rounded,
      aliases: <String>[
        'attraction',
        'viewpoint',
        'theme_park',
        'historic',
        'scenic_viewpoint',
        'tourist_attraction',
        'lighthouse',
        'waterfall',
        'dam',
        'cave',
        'island',
        'mountain',
        'mountain_hut',
        'beach',
        'stadium',
        'soccer_stadium',
        'basketball_stadium',
        'football_stadium',
        'hockey_stadium',
        'baseball_stadium',
        'tennis_stadium',
        'racetrack',
        'racecourse',
        'casino',
        'amusement_park',
        'theme_park_attraction',
        'fair_grounds',
      ],
    ),
    PoiCategoryDefinition(
      key: 'bar',
      label: 'Nightlife',
      ringColor: Color(0xFFBE185D),
      fillColor: Color(0xFFEC4899),
      markerAssetKey: 'bar',
      iconData: Icons.local_bar_rounded,
      aliases: <String>[
        'bar',
        'pub',
        'night_club',
        'nightclub',
        'nightlife',
        'liquor_store',
        'alcohol',
        'wine_bar',
        'beer_garden',
        'cocktail_bar',
        'lounge',
        'karaoke_bar',
        'gay_bar',
        'beach_bar',
        'dive_bar',
        'stripclub',
        'brewery',
        'speakeasy',
        'champagne_bar',
        'sake_bar',
        'beer_bar',
        'hookah_lounge',
        'whiskey_bar',
        'tiki_bar',
        'gastropub',
        'biergarten',
      ],
    ),
    PoiCategoryDefinition(
      key: 'shopping',
      label: 'Shopping',
      ringColor: Color(0xFFB45309),
      fillColor: Color(0xFFF59E0B),
      markerAssetKey: 'shopping',
      iconData: Icons.shopping_bag_rounded,
      aliases: <String>[
        'shop',
        'mall',
        'supermarket',
        'marketplace',
        'clothing_store',
        'convenience_store',
        'convenience',
        'electronics',
        'electronics_shop',
        'hardware_store',
        'furniture_store',
        'jewelry_store',
        'flower_shop',
        'book_store',
        'gift_shop',
        'toy_store',
        'pet_store',
        'pharmacy',
        'cosmetics_shop',
        'beauty_store',
        'optician',
        'bicycle_shop',
        'alcohol_shop',
        'vape_shop',
        'tobacco_shop',
        'smoke_shop',
        'camera_shop',
        'watch_store',
        'hobby_shop',
        'antique_shop',
        'thrift_shop',
        'pawnshop',
        'duty_free_shop',
        'outlet_store',
        'luggage_store',
        'music_shop',
        'fabric_store',
        'frame_store',
        'paper_goods_store',
        'kitchen_store',
        'mattress_store',
        'lighting_store',
        'arts_and_craft_store',
        'home_repair',
        'baby_goods_shop',
        'variety_store',
        'pop_up_shop',
        'clothing',
        'shopping_mall',
        'department_store',
      ],
    ),
    PoiCategoryDefinition(
      key: 'hotel',
      label: 'Hotels',
      ringColor: Color(0xFF0369A1),
      fillColor: Color(0xFF0EA5E9),
      markerAssetKey: 'hotel',
      iconData: Icons.hotel_rounded,
      aliases: <String>[
        'hotel',
        'motel',
        'hostel',
        'apartment',
        'guest_house',
        'accommodation',
        'lodging',
        'bed_and_breakfast',
        'vacation_rental',
        'resort',
        'campground',
        'campsite',
      ],
    ),
    PoiCategoryDefinition(
      key: 'transport',
      label: 'Transport',
      ringColor: Color(0xFF334155),
      fillColor: Color(0xFF475569),
      markerAssetKey: 'transport',
      iconData: Icons.train_rounded,
      aliases: <String>[
        'station',
        'airport',
        'airfield',
        'bus_stop',
        'subway_entrance',
        'train_station',
        'rail_station',
        'railway',
        'ferry_terminal',
        'ferry',
        'transit_stop',
        'stop_area',
        'railway_station',
        'bus_station',
        'subway_station',
        'light_rail_station',
        'public_transportation_station',
        'taxi',
        'car_rental',
        'parking_lot',
        'parking',
        'parking_garage',
        'gas_station',
        'fuel',
        'charging_station',
        'train',
        'bus',
        'rail',
        'subway',
        'tram_stop',
        'tram',
        'metro_station',
      ],
    ),
    PoiCategoryDefinition(
      key: 'others',
      label: 'Services',
      ringColor: Color(0xFF475569),
      fillColor: Color(0xFF64748B),
      markerAssetKey: 'others',
      iconData: Icons.public_rounded,
      aliases: <String>[
        'poi',
        'office',
        'educational',
        'healthcare',
        'public',
        'bank',
        'atm',
        'hospital',
        'clinic',
        'post_office',
        'medical_clinic',
        'doctors_office',
        'dentist',
        'veterinarian',
        'police_station',
        'fire_station',
        'government_offices',
        'library',
        'school',
        'university',
        'college',
        'community_center',
        'mosque',
        'church',
        'temple',
        'synagogue',
        'buddhist_temple',
        'cemetery',
        'laundry',
        'dry_cleaners',
        'salon',
        'hairdresser',
        'barber',
        'spa',
        'gym',
        'fitness_center',
        'yoga_studio',
        'pilates_studio',
        'sports_club',
        'swimming_pool',
        'tennis_courts',
        'golf_course',
        'bowling_alley',
        'arcade',
        'laser_tag',
        'billiards',
        'karaoke',
        'karaoke_box',
        'dance_studio',
        'recording_studio',
        'television_studio',
        'radio_studio',
        'design_studio',
        'coworking_space',
        'event_space',
        'conference_center',
        'offices',
        'factory',
        'warehouse',
        'storage',
        'services',
        'it',
        'consulting',
        'advertising_agency',
        'notary',
        'lawyer',
        'photographer',
        'event_planner',
        'copyshop',
        'employment_agency',
        'medical_laboratory',
        'care_services',
        'rehabilitation_center',
        'psychotherapist',
        'chiropractor',
        'physiotherapist',
        'alternative_healthcare',
        'assisted_living_facility',
      ],
    ),
  ];

  /// Web `UI_KEY_TO_BACKEND_CATEGORY` — chat/polygon rota için backend string’leri
  static const Map<String, String> uiKeyToBackendCategory = <String, String>{
    'restaurant': 'restaurant',
    'cafe': 'cafe',
    'museum': 'museum',
    'monuments': 'monument',
    'park': 'park',
    'attraction': 'attraction',
    'bar': 'bar',
    'shopping': 'shopping',
    'hotel': 'hotel',
    'transport': 'transport',
    'others': 'poi',
  };

  /// Mapbox vektör özellikleri bazen `rail-station`, `fast-food` döner; alias listesi
  /// alt çizgili. Tireleri alt çizgiye çevirerek master mapping tablosuyla hizalarız.
  static String normalizeCategory(String raw) {
    var s = raw.trim().toLowerCase();
    if (s.isEmpty) return s;
    s = s.replaceAll(RegExp(r'[\s\-]+'), '_');
    while (s.contains('__')) {
      s = s.replaceAll('__', '_');
    }
    return s;
  }

  /// Web `poiIconByCategory` — null => eşleşme yok (filtrede her zaman göster)
  static PoiCategoryDefinition? poiCategoryForRaw(String? rawCategory) {
    final c = normalizeCategory(rawCategory ?? '');
    if (c.isEmpty) return null;
    for (final def in all) {
      if (def.aliases.contains(c)) return def;
    }
    return null;
  }

  /// Web `labelByCategory`
  static String? labelForRawCategory(String? rawCategory) =>
      poiCategoryForRaw(rawCategory)?.label;

  /// Web `getSafePoiTitle`
  static String safePoiTitle({
    required String? name,
    required String rawCategory,
  }) {
    final rawName = (name ?? '').trim();
    const invalid = <String>{
      'unnamed',
      'unknown',
      'n/a',
      'na',
      '-',
      'null',
      'undefined',
      '',
    };
    final normalizedName = rawName.toLowerCase();
    final hasValidName =
        rawName.isNotEmpty && !invalid.contains(normalizedName);
    if (hasValidName) return rawName;

    final label = labelForRawCategory(rawCategory);
    if (label != null) return label;

    final cat = rawCategory.trim();
    if (cat.isNotEmpty) return cat[0].toUpperCase() + cat.substring(1);

    return 'Place';
  }

  static PoiCategoryDefinition? definitionForUiKey(String key) {
    final k = normalizeCategory(key);
    for (final def in all) {
      if (def.key == k) return def;
    }
    return null;
  }

  /// Web: eşleşmeyen kategoriler filtrelenmez; eşleşenler seçime tabi.
  /// [treatEmptySelectionAsShowAll]: seçim boşsa tüm eşleşen kategorileri göster (backend null kategori ile uyum).
  static bool passesCategoryFilter({
    required String rawCategory,
    required Set<String> selectedUiKeys,
    bool treatEmptySelectionAsShowAll = true,
  }) {
    if (treatEmptySelectionAsShowAll && selectedUiKeys.isEmpty) {
      return true;
    }
    final icon = poiCategoryForRaw(rawCategory);
    if (icon == null) return true;
    return selectedUiKeys.contains(icon.key);
  }

  static List<String> get defaultSelectedCategoryKeys =>
      all.map((e) => e.key).toList();

  static Map<String, int> countsByUiKey(Iterable<String> rawCategories) {
    final map = <String, int>{for (final d in all) d.key: 0};
    for (final raw in rawCategories) {
      final def = poiCategoryForRaw(raw);
      if (def != null) {
        map[def.key] = (map[def.key] ?? 0) + 1;
      }
    }
    return map;
  }
}
