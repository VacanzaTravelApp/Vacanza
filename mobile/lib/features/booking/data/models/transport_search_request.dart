import 'sort_criteria.dart';

/// UC1.8-MOB3 — Request DTO for `POST /bookings/transportation/search`.
///
/// `returnDate` is nullable (null = one-way).
/// Nullable fields (`budget`, `sortBy`, `returnDate`) are omitted from JSON.
class TransportSearchRequest {
  final String origin;
  final String destination;
  final String departureDate; // YYYY-MM-DD
  final String? returnDate;   // YYYY-MM-DD, null = one-way
  final int adults;
  final double? budget;
  final String currency;
  final SortCriteria? sortBy;

  const TransportSearchRequest({
    required this.origin,
    required this.destination,
    required this.departureDate,
    this.returnDate,
    this.adults = 1,
    this.budget,
    this.currency = 'USD',
    this.sortBy,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'origin': origin,
      'destination': destination,
      'departureDate': departureDate,
      'adults': adults,
      'currency': currency,
    };
    if (returnDate != null) json['returnDate'] = returnDate;
    if (budget != null) json['budget'] = budget;
    if (sortBy != null) json['sortBy'] = sortBy!.apiValue;
    return json;
  }

  /// Creates a copy with updated filter params (used by Apply Filters).
  TransportSearchRequest copyWithFilters({
    double? budget,
    SortCriteria? sortBy,
    bool clearBudget = false,
    bool clearSort = false,
  }) {
    return TransportSearchRequest(
      origin: origin,
      destination: destination,
      departureDate: departureDate,
      returnDate: returnDate,
      adults: adults,
      currency: currency,
      budget: clearBudget ? null : (budget ?? this.budget),
      sortBy: clearSort ? null : (sortBy ?? this.sortBy),
    );
  }

  @override
  String toString() =>
      'TransportSearchRequest($origin→$destination, $departureDate, '
      'adults=$adults, budget=$budget, sort=$sortBy)';
}
