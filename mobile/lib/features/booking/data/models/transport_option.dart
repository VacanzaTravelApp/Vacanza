/// UC1.8-MOB3 — Response DTO for a single transportation (flight) result.
///
/// Maps from the JSON array items returned by
/// `POST /bookings/transportation/search`.
class TransportOption {
  final String carrier;
  final String origin;
  final String destination;
  final String departureTime; // ISO 8601 local datetime
  final String arrivalTime;   // ISO 8601 local datetime
  final String duration;      // ISO 8601 duration, e.g. "PT3H15M"
  final double price;
  final String currency;
  final int stops;
  final String externalBookingUrl;

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
    );
  }

  @override
  String toString() =>
      'TransportOption($carrier $origin→$destination, $price $currency, '
      'stops=$stops)';
}
