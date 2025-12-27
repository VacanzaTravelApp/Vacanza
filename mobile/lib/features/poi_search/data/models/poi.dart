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
    // ✅ Null / tip sapması olursa patlamasın diye güvenli parse
    final lat = (json["latitude"] as num?)?.toDouble() ?? 0.0;
    final lng = (json["longitude"] as num?)?.toDouble() ?? 0.0;

    return Poi(
      poiId: (json["poiId"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      category: (json["category"] ?? "").toString(),
      latitude: lat,
      longitude: lng,
      rating: (json["rating"] as num?)?.toDouble(),
      priceLevel: json["priceLevel"]?.toString(),
      externalId: json["externalId"]?.toString(),
    );
  }
}