/// Response payload from `POST /checkins/auto`.
///
/// All fields parsed null-safely — backend may omit fields
/// when no check-in occurred (e.g. user too far from any POI).
class AutoCheckinResponseDto {
  final String? checkInId;
  final String? poiId;
  final String? poiName;
  final String? checkedInAt;
  final String message;
  final bool success;
  final bool gamificationTriggered;

  const AutoCheckinResponseDto({
    this.checkInId,
    this.poiId,
    this.poiName,
    this.checkedInAt,
    required this.message,
    required this.success,
    required this.gamificationTriggered,
  });

  factory AutoCheckinResponseDto.fromJson(Map<String, dynamic> json) {
    return AutoCheckinResponseDto(
      checkInId: json['checkInId']?.toString(),
      poiId: json['poiId']?.toString(),
      poiName: json['poiName']?.toString(),
      checkedInAt: json['checkedInAt']?.toString(),
      message: (json['message'] ?? '').toString(),
      success: json['success'] == true,
      gamificationTriggered: json['gamificationTriggered'] == true,
    );
  }

  @override
  String toString() =>
      'AutoCheckinResponseDto(success: $success, checkInId: $checkInId, '
      'poiName: $poiName, gamificationTriggered: $gamificationTriggered)';
}
