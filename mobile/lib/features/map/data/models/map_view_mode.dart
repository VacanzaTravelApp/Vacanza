/// Harita görünüm modu.
/// Mapbox entegrasyonu gelene kadar sadece UI state olarak kullanılacak.
/// İleride Mapbox style/layer switch burada belirlenen moda bağlanacak.
enum MapViewMode {
  mode2D,
  mode3D,
  satellite;

  /// UI üzerinde gösterilecek kısa etiket.
  String get label {
    switch (this) {
      case MapViewMode.mode2D:
        return '2D';
      case MapViewMode.mode3D:
        return '3D';
      case MapViewMode.satellite:
        return 'SAT';
    }
  }

  /// Mode toggle için sıradaki moda geçiş.
  MapViewMode next() {
    switch (this) {
      case MapViewMode.mode2D:
        return MapViewMode.mode3D;
      case MapViewMode.mode3D:
        return MapViewMode.satellite;
      case MapViewMode.satellite:
        return MapViewMode.mode2D;
    }
  }
}