/// Domain model for travel statistics (GET /users/me/stats).
class TravelStats {
  final int visitedPoisCount;
  final DateTime? lastVisitDate;
  final String? lastVisitPoiName;
  final String? favoriteCategory;
  final int distinctCategoriesCount;

  const TravelStats({
    required this.visitedPoisCount,
    this.lastVisitDate,
    this.lastVisitPoiName,
    this.favoriteCategory,
    required this.distinctCategoriesCount,
  });
}
