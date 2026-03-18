class ArNearbyPoiDto {
  final String poiId;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final double distanceMeters;

  const ArNearbyPoiDto({
    required this.poiId,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
  });

  factory ArNearbyPoiDto.fromJson(Map<String, dynamic> json) {
    return ArNearbyPoiDto(
      poiId: (json['poiId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
    );
  }
}

