class Poi {
  final String poiId;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final double? rating;
  final String? priceLevel;
  final String? externalId;

  const Poi({
    required this.poiId,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.rating,
    this.priceLevel,
    this.externalId,
  });

  factory Poi.fromJson(Map<String, dynamic> json) {
    final lat = (json["latitude"] as num?)?.toDouble() ?? 0.0;
    final lng = (json["longitude"] as num?)?.toDouble() ?? 0.0;

    String _fallbackNameFromCategory(String rawCategory) {
      final c = rawCategory.trim().toLowerCase();

      switch (c) {
        case 'parks':
        case 'park':
          return 'Park';
        case 'museums':
        case 'museum':
          return 'Museum';
        case 'monuments':
        case 'monument':
          return 'Monument';
        case 'restaurant':
        case 'restaurant':
          return 'Restaurant';
        case 'cafe':
        case 'cafes':
          return 'Cafe';
        default:
          if (c.isEmpty) return 'Place';
          return c[0].toUpperCase() + c.substring(1); // son çare
      }
    }

    bool _isUnnamed(String s) {
      final n = s.trim().toLowerCase();
      return n.isEmpty || n == 'unnamed' || n == 'unamed';
    }

    final category = (json["category"] ?? "").toString();
    final rawName = (json["name"] ?? "").toString();

    final name = _isUnnamed(rawName) ? _fallbackNameFromCategory(category) : rawName;

    return Poi(
      poiId: (json["poiId"] ?? "").toString(),
      name: name,
      category: category,
      latitude: lat,
      longitude: lng,
      rating: (json["rating"] as num?)?.toDouble(),
      priceLevel: json["priceLevel"]?.toString(),
      externalId: json["externalId"]?.toString(),
    );
  }
}