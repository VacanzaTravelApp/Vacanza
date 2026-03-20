class ArPoi {
  final String id;
  final String name;
  final String categoryKey;
  final double distanceMeters;
  final double bearingDegrees; // 0–360, relative to north

  const ArPoi({
    required this.id,
    required this.name,
    required this.categoryKey,
    required this.distanceMeters,
    required this.bearingDegrees,
  });
}

