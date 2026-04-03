import '../../data/models/accommodation_option.dart';
import '../../data/models/accommodation_search_request.dart';
import '../../data/models/airport_autocomplete_slot.dart';
import '../../data/models/sort_criteria.dart';
import '../../data/models/transport_option.dart';
import '../../data/models/transport_search_request.dart';

// ─────────────────────────────────────────────────────────────────
// UC1.8-MOB2 — Sealed state hierarchy for BookingCubit.
//
// Follows the repo pattern from GamificationState (sealed + typed payloads).
// ─────────────────────────────────────────────────────────────────

/// Booking type toggle.
enum BookingType { hotels, flights }

/// Base sealed class for booking states.
sealed class BookingState {
  const BookingState();
}

/// Default state — search form is shown.
class BookingSearch extends BookingState {
  final BookingType type;

  /// Origin / destination autocomplete — independent of flight search results.
  final AirportAutocompleteSlot originAirport;
  final AirportAutocompleteSlot destinationAirport;

  const BookingSearch({
    this.type = BookingType.hotels,
    this.originAirport = const AirportAutocompleteSlot(),
    this.destinationAirport = const AirportAutocompleteSlot(),
  });
}

/// Search in progress.
class BookingLoading extends BookingState {
  final BookingType type;
  const BookingLoading({required this.type});
}

/// Hotel search returned results.
class BookingHotelResults extends BookingState {
  final List<AccommodationOption> results;
  final String summary; // e.g. "PAR · Jul 1–5 · 2 adults"
  final AccommodationSearchRequest lastRequest;
  final double? budget;
  final SortCriteria? sortBy;

  const BookingHotelResults({
    required this.results,
    required this.summary,
    required this.lastRequest,
    this.budget,
    this.sortBy,
  });
}

/// Flight search returned results.
class BookingFlightResults extends BookingState {
  final List<TransportOption> results;
  final String summary;
  final TransportSearchRequest lastRequest;
  final double? budget;
  final SortCriteria? sortBy;

  const BookingFlightResults({
    required this.results,
    required this.summary,
    required this.lastRequest,
    this.budget,
    this.sortBy,
  });
}

/// Search returned zero results (not an error).
class BookingEmpty extends BookingState {
  final BookingType type;
  final String summary;
  const BookingEmpty({required this.type, required this.summary});
}

/// Search failed (400 / 502 / network).
class BookingError extends BookingState {
  final BookingType type;
  final String message;
  const BookingError({required this.type, required this.message});
}

/// Filters view — retains context for back-navigation + re-run.
class BookingFilters extends BookingState {
  final BookingType type;
  final double? currentBudget;
  final SortCriteria? currentSort;

  /// The summary string for display in filter header.
  final String summary;

  const BookingFilters({
    required this.type,
    this.currentBudget,
    this.currentSort,
    required this.summary,
  });
}
