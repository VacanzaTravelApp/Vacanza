import '../models/check_in.dart';

/// DTO for a single item in GET /users/me/checkins.
class CheckInDto {
  final String checkInId;
  final String poiId;
  final String poiName;
  final String category;
  final String checkedInAtIso;
  final double latitude;
  final double longitude;

  const CheckInDto({
    required this.checkInId,
    required this.poiId,
    required this.poiName,
    required this.category,
    required this.checkedInAtIso,
    required this.latitude,
    required this.longitude,
  });

  factory CheckInDto.fromJson(Map<String, dynamic> json) {
    return CheckInDto(
      checkInId: (json['checkInId'] ?? '').toString(),
      poiId: (json['poiId'] ?? '').toString(),
      poiName: (json['poiName'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      checkedInAtIso: (json['checkedInAt'] ?? '').toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  CheckIn toDomain() {
    final checkedInAt = DateTime.tryParse(checkedInAtIso) ?? DateTime.now();
    return CheckIn(
      checkInId: checkInId,
      poiId: poiId,
      poiName: poiName,
      category: category,
      checkedInAt: checkedInAt,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
