/// Domain model for a single check-in (GET /users/me/checkins).
class CheckIn {
  final String checkInId;
  final String poiId;
  final String poiName;
  final String category;
  final DateTime checkedInAt;
  final double latitude;
  final double longitude;

  const CheckIn({
    required this.checkInId,
    required this.poiId,
    required this.poiName,
    required this.category,
    required this.checkedInAt,
    required this.latitude,
    required this.longitude,
  });
}
