import '../models/travel_stats.dart';

/// DTO for GET /users/me/stats.
class TravelStatsDto {
  final int visitedPoisCount;
  final String? lastVisitDateIso;
  final String? lastVisitPoiName;
  final String? favoriteCategory;
  final int distinctCategoriesCount;

  const TravelStatsDto({
    required this.visitedPoisCount,
    this.lastVisitDateIso,
    this.lastVisitPoiName,
    this.favoriteCategory,
    required this.distinctCategoriesCount,
  });

  factory TravelStatsDto.fromJson(Map<String, dynamic> json) {
    return TravelStatsDto(
      visitedPoisCount: (json['visitedPoisCount'] as num?)?.toInt() ?? 0,
      lastVisitDateIso: json['lastVisitDate']?.toString(),
      lastVisitPoiName: json['lastVisitPoiName']?.toString(),
      favoriteCategory: json['favoriteCategory']?.toString(),
      distinctCategoriesCount:
          (json['distinctCategoriesCount'] as num?)?.toInt() ?? 0,
    );
  }

  TravelStats toDomain() {
    DateTime? lastVisitDate;
    if (lastVisitDateIso != null && lastVisitDateIso!.isNotEmpty) {
      lastVisitDate = DateTime.tryParse(lastVisitDateIso!);
    }
    return TravelStats(
      visitedPoisCount: visitedPoisCount,
      lastVisitDate: lastVisitDate,
      lastVisitPoiName: lastVisitPoiName,
      favoriteCategory: favoriteCategory,
      distinctCategoriesCount: distinctCategoriesCount,
    );
  }
}
