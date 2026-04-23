/// Harita taban stili — web [MapPage.jsx] [STYLES] ile aynı üç seçenek.
enum MapBasemap {
  streets,
  dark,
  satellite,
}

extension MapBasemapX on MapBasemap {
  String get label {
    switch (this) {
      case MapBasemap.streets:
        return 'STR';
      case MapBasemap.dark:
        return 'DARK';
      case MapBasemap.satellite:
        return 'SAT';
    }
  }

  /// streets → dark → satellite → streets
  MapBasemap next() {
    switch (this) {
      case MapBasemap.streets:
        return MapBasemap.dark;
      case MapBasemap.dark:
        return MapBasemap.satellite;
      case MapBasemap.satellite:
        return MapBasemap.streets;
    }
  }
}
