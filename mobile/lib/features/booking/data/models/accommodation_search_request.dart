import 'sort_criteria.dart';

class AccommodationSearchRequest {
  /// Natural-language hotel query, e.g. "Hotels in Paris",
  /// "Bali resorts", "Boutique hotels near Eiffel Tower".
  final String query;
  final String checkInDate;  // YYYY-MM-DD
  final String checkOutDate; // YYYY-MM-DD
  final int adults;
  final double? budget;
  final String currency;
  final SortCriteria? sortBy;

  const AccommodationSearchRequest({
    required this.query,
    required this.checkInDate,
    required this.checkOutDate,
    this.adults = 1,
    this.budget,
    this.currency = 'USD',
    this.sortBy,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'query': query,
      'checkInDate': checkInDate,
      'checkOutDate': checkOutDate,
      'adults': adults,
      'currency': currency,
    };
    if (budget != null) json['budget'] = budget;
    if (sortBy != null) json['sortBy'] = sortBy!.apiValue;
    return json;
  }

  /// Creates a copy with updated filter params (used by Apply Filters).
  AccommodationSearchRequest copyWithFilters({
    double? budget,
    SortCriteria? sortBy,
    bool clearBudget = false,
    bool clearSort = false,
  }) {
    return AccommodationSearchRequest(
      query: query,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      adults: adults,
      currency: currency,
      budget: clearBudget ? null : (budget ?? this.budget),
      sortBy: clearSort ? null : (sortBy ?? this.sortBy),
    );
  }

  @override
  String toString() =>
      'AccommodationSearchRequest(query="$query", $checkInDate→$checkOutDate, '
      'adults=$adults, budget=$budget, sort=$sortBy)';
}
