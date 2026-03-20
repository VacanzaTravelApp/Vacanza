/// UC1.8-MOB3 — Response DTO for a single transportation (flight) result.
///
/// Maps from the JSON array items returned by
/// `POST /bookings/transportation/search`.
class TransportOption {
  final String carrier;
  final String origin;
  final String destination;
  final String departureTime; // String, e.g. "2025-07-01 08:30"
  final String arrivalTime;   // String, e.g. "2025-07-01 11:45"
  final String duration;      // e.g. "3h 15m" (treated as opaque string)
  final double price;
  final String currency;
  final int stops;
  final String externalBookingUrl;

  // Google Flights enriched fields
  final String? airlineLogo;
  final String? flightNumber;
  final String? travelClass;
  final String? bookingToken;

  const TransportOption({
    required this.carrier,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.price,
    required this.currency,
    required this.stops,
    required this.externalBookingUrl,
    this.airlineLogo,
    this.flightNumber,
    this.travelClass,
    this.bookingToken,
  });

  factory TransportOption.fromJson(Map<String, dynamic> json) {
    return TransportOption(
      carrier: (json['carrier'] ?? '').toString(),
      origin: (json['origin'] ?? '').toString(),
      destination: (json['destination'] ?? '').toString(),
      departureTime: (json['departureTime'] ?? '').toString(),
      arrivalTime: (json['arrivalTime'] ?? '').toString(),
      duration: (json['duration'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: (json['currency'] ?? 'USD').toString(),
      stops: (json['stops'] as num?)?.toInt() ?? 0,
      externalBookingUrl: (json['externalBookingUrl'] ?? '').toString(),
      airlineLogo: (json['airlineLogo'] as String?),
      flightNumber: (json['flightNumber'] as String?),
      travelClass: (json['travelClass'] as String?),
      bookingToken: (json['bookingToken'] as String?),
    );
  }

  @override
  String toString() =>
      'TransportOption($carrier $origin→$destination, $price $currency, '
      'stops=$stops, flightNumber=$flightNumber, travelClass=$travelClass)';
}
