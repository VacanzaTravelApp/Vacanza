/// UC1.8-MOB3 — Response DTO for a single accommodation result.
///
/// Maps from the JSON array items returned by
/// `POST /bookings/accommodations/search`.
class AccommodationOption {
  final String hotelName;
  final String hotelId;
  final String address;
  final double price;
  final double? pricePerNight;
  final String currency;
  final double? rating; // nullable per contract
  final String externalBookingUrl;

  // SerpApi (Google Hotels) enriched fields
  final String? imageUrl;
  final int? hotelClass;
  final int? totalReviews;
  final String? providerName;
  final String? description;
  final double? latitude;
  final double? longitude;

  const AccommodationOption({
    required this.hotelName,
    required this.hotelId,
    required this.address,
    required this.price,
    this.pricePerNight,
    required this.currency,
    this.rating,
    required this.externalBookingUrl,
    this.imageUrl,
    this.hotelClass,
    this.totalReviews,
    this.providerName,
    this.description,
    this.latitude,
    this.longitude,
  });

  factory AccommodationOption.fromJson(Map<String, dynamic> json) {
    return AccommodationOption(
      hotelName: (json['hotelName'] ?? '').toString(),
      hotelId: (json['hotelId'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble(),
      currency: (json['currency'] ?? 'USD').toString(),
      rating: (json['rating'] as num?)?.toDouble(),
      externalBookingUrl: (json['externalBookingUrl'] ?? '').toString(),
      imageUrl: (json['imageUrl'] as String?) ?? (json['thumbnailUrl'] as String?),
      hotelClass: (json['hotelClass'] as num?)?.toInt(),
      totalReviews: (json['totalReviews'] as num?)?.toInt(),
      providerName: (json['providerName'] as String?),
      description: (json['description'] as String?),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() =>
      'AccommodationOption($hotelName, $price $currency, rating=$rating, '
      'hotelClass=$hotelClass, reviews=$totalReviews, provider=$providerName)';
}
