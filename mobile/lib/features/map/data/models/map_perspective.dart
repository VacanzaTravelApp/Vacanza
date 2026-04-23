/// 2D / 3D kamera — web [MapPage] `is3D` ile eşlenik.
enum MapPerspective {
  mode2D,
  mode3D,
}

extension MapPerspectiveX on MapPerspective {
  String get label => this == MapPerspective.mode3D ? '3D' : '2D';

  MapPerspective toggle() =>
      this == MapPerspective.mode2D ? MapPerspective.mode3D : MapPerspective.mode2D;
}
