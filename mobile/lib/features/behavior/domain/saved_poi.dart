class SavedPoi {
  const SavedPoi({
    required this.poiKey,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  final String poiKey;
  final String name;
  final String? category;
  final double? latitude;
  final double? longitude;
  final DateTime? updatedAt;

  bool get hasCoords =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite;

  factory SavedPoi.fromJson(dynamic json) {
    if (json is! Map) {
      throw const FormatException('Invalid SavedPoi json');
    }

    String str(dynamic v) => v?.toString() ?? '';
    double? dbl(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    final poiKey = str(json['poiKey']).trim();
    final name = str(json['name']).trim();
    if (poiKey.isEmpty || name.isEmpty) {
      throw const FormatException('SavedPoi missing required fields');
    }

    final updatedAtRaw = str(json['updatedAt']).trim();
    final updatedAt = updatedAtRaw.isEmpty ? null : DateTime.tryParse(updatedAtRaw);

    final categoryRaw = str(json['category']).trim();
    final category = categoryRaw.isEmpty ? null : categoryRaw;

    return SavedPoi(
      poiKey: poiKey,
      name: name,
      category: category,
      latitude: dbl(json['latitude']),
      longitude: dbl(json['longitude']),
      updatedAt: updatedAt,
    );
  }
}

