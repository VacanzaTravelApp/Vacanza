class ArPoi {
  final String id;
  final String name;
  final String categoryKey;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final double bearingDegrees; // 0–360, relative to north

  /// Foursquare / backend external id — same as [Poi.externalId] for feedback affinity keys.
  final String? externalId;

  const ArPoi({
    required this.id,
    required this.name,
    required this.categoryKey,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.bearingDegrees,
    this.externalId,
  });
}

