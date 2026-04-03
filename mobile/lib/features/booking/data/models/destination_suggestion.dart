import 'package:equatable/equatable.dart';

/// One row from `GET /bookings/destinations/search`.
///
/// Use [searchQuery] in [AccommodationSearchRequest.query], not [displayName].
class DestinationSuggestion extends Equatable {
  final String city;
  final String country;
  final String displayName;
  final String searchQuery;

  const DestinationSuggestion({
    required this.city,
    required this.country,
    required this.displayName,
    required this.searchQuery,
  });

  factory DestinationSuggestion.fromJson(Map<String, dynamic> json) {
    return DestinationSuggestion(
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      searchQuery: json['searchQuery'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [city, country, displayName, searchQuery];
}
