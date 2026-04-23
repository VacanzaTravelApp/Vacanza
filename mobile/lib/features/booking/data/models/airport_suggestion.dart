import 'package:equatable/equatable.dart';

/// One row from `GET /bookings/airports/search`.
///
/// Send [resolvedSearchId] as `origin` / `destination` in
/// [TransportSearchRequest] (`iataCode` when present, else `kgmid`).
class AirportSuggestion extends Equatable {
  final String? iataCode;
  final String name;
  final String city;
  final String country;
  final String? kgmid;

  const AirportSuggestion({
    this.iataCode,
    required this.name,
    required this.city,
    required this.country,
    this.kgmid,
  });

  factory AirportSuggestion.fromJson(Map<String, dynamic> json) {
    return AirportSuggestion(
      iataCode: json['iataCode'] as String?,
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      kgmid: json['kgmid'] as String?,
    );
  }

  /// Value for `TransportSearchRequest.origin` / `.destination`.
  String get resolvedSearchId {
    final i = iataCode?.trim();
    if (i != null && i.isNotEmpty) return i;
    final k = kgmid?.trim();
    if (k != null && k.isNotEmpty) return k;
    return '';
  }

  /// Dropdown line — show IATA in parentheses only for real IATA codes.
  String get dropdownLabel {
    if (name.isEmpty) return resolvedSearchId;
    final code = iataCode?.trim();
    if (code != null &&
        code.isNotEmpty &&
        RegExp(r'^[A-Z]{2,4}$').hasMatch(code)) {
      return '$name ($code)';
    }
    return name;
  }

  @override
  List<Object?> get props => [iataCode, name, city, country, kgmid];
}
