/// UC1.8-MOB3 — Response DTO for a single accommodation result.
///
/// Maps from the JSON array items returned by
/// `POST /bookings/accommodations/search`.
class AccommodationOption {
  final String hotelName;
  final String hotelId;
  final String address;
  final double price;
  final String currency;
  final double? rating; // nullable per contract
  final String externalBookingUrl;

  const AccommodationOption({
    required this.hotelName,
    required this.hotelId,
    required this.address,
    required this.price,
    required this.currency,
    this.rating,
    required this.externalBookingUrl,
  });

  factory AccommodationOption.fromJson(Map<String, dynamic> json) {
    return AccommodationOption(
      hotelName: (json['hotelName'] ?? '').toString(),
      hotelId: (json['hotelId'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: (json['currency'] ?? 'USD').toString(),
      rating: (json['rating'] as num?)?.toDouble(),
      externalBookingUrl: (json['externalBookingUrl'] ?? '').toString(),
    );
  }

  @override
  String toString() =>
      'AccommodationOption($hotelName, $price $currency, rating=$rating)';
}
