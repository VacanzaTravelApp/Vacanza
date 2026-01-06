

enum MapViewMode { mode2D, mode3D, satellite }

extension MapViewModeX on MapViewMode {
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

  /// 2D -> 3D -> SAT -> 2D
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