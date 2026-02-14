/// Request payload for `POST /checkins/auto`.
class AutoCheckinRequestDto {
  final double latitude;
  final double longitude;
  final List<String> candidatePoiIds;

  const AutoCheckinRequestDto({
    required this.latitude,
    required this.longitude,
    required this.candidatePoiIds,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'candidatePoiIds': candidatePoiIds,
      };
}
