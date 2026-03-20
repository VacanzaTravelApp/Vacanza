/// UC1.8-MOB3 — Sort criteria enum.
///
/// Maps UI sort labels to API values sent in request body.
enum SortCriteria {
  priceAsc('PRICE_ASC'),
  priceDesc('PRICE_DESC'),
  ratingDesc('RATING_DESC');

  /// Value sent to the backend (e.g. `"PRICE_ASC"`).
  final String apiValue;
  const SortCriteria(this.apiValue);
}
