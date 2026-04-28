import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/accommodation_search_request.dart';
import '../../data/models/booking_currency.dart';
import '../../data/models/airport_autocomplete_slot.dart';
import '../../data/models/airport_suggestion.dart';
import '../../data/models/destination_autocomplete_slot.dart';
import '../../data/models/destination_suggestion.dart';
import '../../data/models/sort_criteria.dart';
import '../../data/models/transport_search_request.dart';
import '../../data/repositories/booking_repository.dart';
import 'booking_state.dart';

/// UC1.8-MOB2/MOB5 — Booking flow controller.
///
/// Manages the bottom-sheet state machine:
///   Search → Loading → Results / Empty / Error
///   Results → Filters → (Apply / Reset) → Loading → Results
///
/// Logs every decision with [BOOKING_CUBIT] tag.
class BookingCubit extends Cubit<BookingState> {
  final BookingRepository _repository;

  BookingCubit({required BookingRepository repository})
      : _repository = repository,
        super(const BookingSearch());

  int _originSuggestionSeq = 0;
  int _destSuggestionSeq = 0;
  int _hotelDestinationSeq = 0;

  // ── Internal state for retry / filter re-run ──────────────────
  AccommodationSearchRequest? _lastHotelRequest;
  TransportSearchRequest? _lastFlightRequest;
  BookingType _currentType = BookingType.hotels;

  /// Exposes last hotel request for form state restore (MOB6).
  AccommodationSearchRequest? get lastHotelRequest => _lastHotelRequest;

  /// Exposes last flight request for form state restore (MOB6).
  TransportSearchRequest? get lastFlightRequest => _lastFlightRequest;

  // ── Kept for back-navigation from filters ─────────────────────
  BookingState? _previousResultsState;

  // ──────────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────────

  /// Switches between Hotels / Flights and resets to Search.
  void switchType(BookingType type) {
    _currentType = type;
    String? keepCurrency;
    if (state is BookingSearch) {
      keepCurrency = (state as BookingSearch).currency;
    }
    log('[BOOKING_CUBIT] switchType → $type');
    emit(_searchWithClearedAutocomplete(type, currency: keepCurrency));
  }

  BookingSearch _searchWithClearedAutocomplete(
    BookingType type, {
    String? currency,
  }) {
    final resolved = BookingCurrencies.normalize(
      currency ??
          _lastHotelRequest?.currency ??
          _lastFlightRequest?.currency,
    );
    return BookingSearch(
      type: type,
      currency: resolved,
      originAirport: const AirportAutocompleteSlot(),
      destinationAirport: const AirportAutocompleteSlot(),
      hotelDestination: const DestinationAutocompleteSlot(),
    );
  }

  /// Updates shared currency (hotels + flights). Only in [BookingSearch].
  void setCurrency(String code) {
    final s = state;
    if (s is! BookingSearch) return;
    final next = BookingCurrencies.normalize(code);
    if (next == s.currency) return;
    emit(BookingSearch(
      type: s.type,
      currency: next,
      originAirport: s.originAirport,
      destinationAirport: s.destinationAirport,
      hotelDestination: s.hotelDestination,
    ));
  }

  // ── Airport autocomplete (TASK-2) ─────────────────────────────

  void _patchBookingSearch({
    AirportAutocompleteSlot? originAirport,
    AirportAutocompleteSlot? destinationAirport,
    DestinationAutocompleteSlot? hotelDestination,
  }) {
    final s = state;
    if (s is! BookingSearch) return;
    emit(BookingSearch(
      type: s.type,
      currency: s.currency,
      originAirport: originAirport ?? s.originAirport,
      destinationAirport: destinationAirport ?? s.destinationAirport,
      hotelDestination: hotelDestination ?? s.hotelDestination,
    ));
  }

  /// Call when the user edits the origin field; clears [selected] if text diverges.
  void onOriginFieldTextChanged(String text) {
    final s = state;
    if (s is! BookingSearch) return;
    final sel = s.originAirport.selected;
    if (sel != null && text != sel.dropdownLabel) {
      _patchBookingSearch(
        originAirport: s.originAirport.copyWith(clearSelected: true),
      );
    }
  }

  /// Call when the user edits the destination field.
  void onDestinationFieldTextChanged(String text) {
    final s = state;
    if (s is! BookingSearch) return;
    final sel = s.destinationAirport.selected;
    if (sel != null && text != sel.dropdownLabel) {
      _patchBookingSearch(
        destinationAirport: s.destinationAirport.copyWith(clearSelected: true),
      );
    }
  }

  /// Clears suggestions when query is under 2 characters or field emptied.
  void clearOriginAirportSuggestions() {
    final s = state;
    if (s is! BookingSearch) return;
    _originSuggestionSeq++;
    _patchBookingSearch(
      originAirport: s.originAirport.copyWith(
        clearSuggestions: true,
        loadingSuggestions: false,
        clearSuggestionError: true,
      ),
    );
  }

  void clearDestinationAirportSuggestions() {
    final s = state;
    if (s is! BookingSearch) return;
    _destSuggestionSeq++;
    _patchBookingSearch(
      destinationAirport: s.destinationAirport.copyWith(
        clearSuggestions: true,
        loadingSuggestions: false,
        clearSuggestionError: true,
      ),
    );
  }

  Future<void> fetchOriginAirportSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      clearOriginAirportSuggestions();
      return;
    }

    final s = state;
    if (s is! BookingSearch) return;

    final seq = ++_originSuggestionSeq;
    _patchBookingSearch(
      originAirport: s.originAirport.copyWith(
        loadingSuggestions: true,
        clearSuggestionError: true,
      ),
    );

    try {
      final list = await _repository.searchAirports(trimmed);
      if (isClosed) return;
      final cur = state;
      if (cur is! BookingSearch || seq != _originSuggestionSeq) return;

      _patchBookingSearch(
        originAirport: cur.originAirport.copyWith(
          suggestions: list,
          loadingSuggestions: false,
          clearSuggestionError: true,
        ),
      );
    } on BookingException catch (e) {
      if (isClosed) return;
      final cur = state;
      if (cur is! BookingSearch || seq != _originSuggestionSeq) return;
      _patchBookingSearch(
        originAirport: cur.originAirport.copyWith(
          loadingSuggestions: false,
          clearSuggestions: true,
          suggestionError: e.message,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final cur = state;
      if (cur is! BookingSearch || seq != _originSuggestionSeq) return;
      _patchBookingSearch(
        originAirport: cur.originAirport.copyWith(
          loadingSuggestions: false,
          clearSuggestions: true,
          suggestionError: 'Could not load suggestions. Please try again.',
        ),
      );
    }
  }

  Future<void> fetchDestinationAirportSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      clearDestinationAirportSuggestions();
      return;
    }

    final s = state;
    if (s is! BookingSearch) return;

    final seq = ++_destSuggestionSeq;
    _patchBookingSearch(
      destinationAirport: s.destinationAirport.copyWith(
        loadingSuggestions: true,
        clearSuggestionError: true,
      ),
    );

    try {
      final list = await _repository.searchAirports(trimmed);
      if (isClosed) return;
      final cur = state;
      if (cur is! BookingSearch || seq != _destSuggestionSeq) return;

      _patchBookingSearch(
        destinationAirport: cur.destinationAirport.copyWith(
          suggestions: list,
          loadingSuggestions: false,
          clearSuggestionError: true,
        ),
      );
    } on BookingException catch (e) {
      if (isClosed) return;
      final cur = state;
      if (cur is! BookingSearch || seq != _destSuggestionSeq) return;
      _patchBookingSearch(
        destinationAirport: cur.destinationAirport.copyWith(
          loadingSuggestions: false,
          clearSuggestions: true,
          suggestionError: e.message,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final cur = state;
      if (cur is! BookingSearch || seq != _destSuggestionSeq) return;
      _patchBookingSearch(
        destinationAirport: cur.destinationAirport.copyWith(
          loadingSuggestions: false,
          clearSuggestions: true,
          suggestionError: 'Could not load suggestions. Please try again.',
        ),
      );
    }
  }

  void selectOriginAirport(AirportSuggestion suggestion) {
    final s = state;
    if (s is! BookingSearch) return;
    _patchBookingSearch(
      originAirport: s.originAirport.copyWith(
        selected: suggestion,
        clearSuggestions: true,
        loadingSuggestions: false,
        clearSuggestionError: true,
      ),
    );
  }

  void selectDestinationAirport(AirportSuggestion suggestion) {
    final s = state;
    if (s is! BookingSearch) return;
    _patchBookingSearch(
      destinationAirport: s.destinationAirport.copyWith(
        selected: suggestion,
        clearSuggestions: true,
        loadingSuggestions: false,
        clearSuggestionError: true,
      ),
    );
  }

  // ── Hotel destination autocomplete (TASK-3) ─────────────────

  void onHotelDestinationFieldTextChanged(String text) {
    final s = state;
    if (s is! BookingSearch) return;
    final sel = s.hotelDestination.selected;
    if (sel != null && text != sel.displayName) {
      _patchBookingSearch(
        hotelDestination: s.hotelDestination.copyWith(clearSelected: true),
      );
    }
  }

  void clearHotelDestinationSuggestions() {
    final s = state;
    if (s is! BookingSearch) return;
    _hotelDestinationSeq++;
    _patchBookingSearch(
      hotelDestination: s.hotelDestination.copyWith(
        clearSuggestions: true,
        loadingSuggestions: false,
        clearSuggestionError: true,
      ),
    );
  }

  Future<void> fetchHotelDestinationSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      clearHotelDestinationSuggestions();
      return;
    }

    final s = state;
    if (s is! BookingSearch) return;

    final seq = ++_hotelDestinationSeq;
    _patchBookingSearch(
      hotelDestination: s.hotelDestination.copyWith(
        loadingSuggestions: true,
        clearSuggestionError: true,
      ),
    );

    try {
      final list = await _repository.searchDestinations(trimmed);
      if (isClosed) return;
      final cur = state;
      if (cur is! BookingSearch || seq != _hotelDestinationSeq) return;

      _patchBookingSearch(
        hotelDestination: cur.hotelDestination.copyWith(
          suggestions: list,
          loadingSuggestions: false,
          clearSuggestionError: true,
        ),
      );
    } on BookingException catch (e) {
      if (isClosed) return;
      final cur = state;
      if (cur is! BookingSearch || seq != _hotelDestinationSeq) return;
      _patchBookingSearch(
        hotelDestination: cur.hotelDestination.copyWith(
          loadingSuggestions: false,
          clearSuggestions: true,
          suggestionError: e.message,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final cur = state;
      if (cur is! BookingSearch || seq != _hotelDestinationSeq) return;
      _patchBookingSearch(
        hotelDestination: cur.hotelDestination.copyWith(
          loadingSuggestions: false,
          clearSuggestions: true,
          suggestionError: 'Could not load suggestions. Please try again.',
        ),
      );
    }
  }

  void selectHotelDestination(DestinationSuggestion suggestion) {
    final s = state;
    if (s is! BookingSearch) return;
    _patchBookingSearch(
      hotelDestination: s.hotelDestination.copyWith(
        selected: suggestion,
        clearSuggestions: true,
        loadingSuggestions: false,
        clearSuggestionError: true,
      ),
    );
  }

  /// Searches hotels via repository.
  Future<void> searchHotels(AccommodationSearchRequest request) async {
    // Guard: ignore if already loading
    if (state is BookingLoading) {
      log('[BOOKING_CUBIT] searchHotels SKIPPED — already loading');
      return;
    }

    _lastHotelRequest = request;
    _currentType = BookingType.hotels;
    final summary = _buildSummary(
      city: request.query,
      dateRange: '${request.checkInDate}–${request.checkOutDate}',
      adults: request.adults,
    );
    log('[BOOKING_CUBIT] searchHotels $request');
    emit(const BookingLoading(type: BookingType.hotels));

    try {
      final results = await _repository.searchHotels(request);
      if (isClosed) return;

      if (results.isEmpty) {
        emit(BookingEmpty(type: BookingType.hotels, summary: summary));
      } else {
        emit(BookingHotelResults(
          results: results,
          summary: summary,
          lastRequest: request,
          budget: request.budget,
          sortBy: request.sortBy,
        ));
      }
    } on BookingException catch (e) {
      if (isClosed) return;
      log('[BOOKING_CUBIT] searchHotels ERROR: ${e.message}');
      emit(BookingError(type: BookingType.hotels, message: e.message));
    } catch (e) {
      if (isClosed) return;
      log('[BOOKING_CUBIT] searchHotels UNEXPECTED: $e');
      emit(const BookingError(type: BookingType.hotels, message: 'Something went wrong. Please try again.'));
    }
  }

  /// Searches flights via repository.
  Future<void> searchFlights(TransportSearchRequest request) async {
    if (state is BookingLoading) {
      log('[BOOKING_CUBIT] searchFlights SKIPPED — already loading');
      return;
    }

    _lastFlightRequest = request;
    _currentType = BookingType.flights;
    final summary = _buildSummary(
      city: '${request.origin}→${request.destination}',
      dateRange: request.returnDate != null
          ? '${request.departureDate}–${request.returnDate}'
          : request.departureDate,
      adults: request.adults,
    );
    log('[BOOKING_CUBIT] searchFlights $request');
    emit(const BookingLoading(type: BookingType.flights));

    try {
      final results = await _repository.searchFlights(request);
      if (isClosed) return;

      if (results.isEmpty) {
        emit(BookingEmpty(type: BookingType.flights, summary: summary));
      } else {
        emit(BookingFlightResults(
          results: results,
          summary: summary,
          lastRequest: request,
          budget: request.budget,
          sortBy: request.sortBy,
        ));
      }
    } on BookingException catch (e) {
      if (isClosed) return;
      log('[BOOKING_CUBIT] searchFlights ERROR: ${e.message}');
      emit(BookingError(type: BookingType.flights, message: e.message));
    } catch (e) {
      if (isClosed) return;
      log('[BOOKING_CUBIT] searchFlights UNEXPECTED: $e');
      emit(const BookingError(type: BookingType.flights, message: 'Something went wrong. Please try again.'));
    }
  }

  /// Opens the Filters view from Results, preserving context.
  void openFilters() {
    final s = state;
    String summary = '';
    double? budget;
    SortCriteria? sort;

    if (s is BookingHotelResults) {
      _previousResultsState = s;
      summary = s.summary;
      budget = s.budget;
      sort = s.sortBy;
    } else if (s is BookingFlightResults) {
      _previousResultsState = s;
      summary = s.summary;
      budget = s.budget;
      sort = s.sortBy;
    } else {
      log('[BOOKING_CUBIT] openFilters SKIPPED — not in results state');
      return;
    }

    log('[BOOKING_CUBIT] openFilters budget=$budget sort=$sort');
    emit(BookingFilters(
      type: _currentType,
      currentBudget: budget,
      currentSort: sort,
      summary: summary,
    ));
  }

  /// Applies updated filter params and re-runs the last search.
  Future<void> applyFilters({double? budget, SortCriteria? sortBy}) async {
    log('[BOOKING_CUBIT] applyFilters budget=$budget sort=$sortBy');
    if (_currentType == BookingType.hotels && _lastHotelRequest != null) {
      final updated = _lastHotelRequest!.copyWithFilters(
        budget: budget,
        sortBy: sortBy,
        clearBudget: budget == null,
        clearSort: sortBy == null,
      );
      return searchHotels(updated);
    }
    if (_currentType == BookingType.flights && _lastFlightRequest != null) {
      final updated = _lastFlightRequest!.copyWithFilters(
        budget: budget,
        sortBy: sortBy,
        clearBudget: budget == null,
        clearSort: sortBy == null,
      );
      return searchFlights(updated);
    }
  }

  /// Resets filters (budget = null, sort = null) and re-runs search.
  Future<void> resetFilters() async {
    log('[BOOKING_CUBIT] resetFilters');
    if (_currentType == BookingType.hotels && _lastHotelRequest != null) {
      final updated = _lastHotelRequest!.copyWithFilters(
        clearBudget: true,
        clearSort: true,
      );
      return searchHotels(updated);
    }
    if (_currentType == BookingType.flights && _lastFlightRequest != null) {
      final updated = _lastFlightRequest!.copyWithFilters(
        clearBudget: true,
        clearSort: true,
      );
      return searchFlights(updated);
    }
  }

  /// Retries the last search (from error or empty state).
  Future<void> retry() async {
    log('[BOOKING_CUBIT] retry type=$_currentType');
    if (_currentType == BookingType.hotels && _lastHotelRequest != null) {
      return searchHotels(_lastHotelRequest!);
    }
    if (_currentType == BookingType.flights && _lastFlightRequest != null) {
      return searchFlights(_lastFlightRequest!);
    }
    // No previous request — go back to search
    if (isClosed) return;
    emit(_searchWithClearedAutocomplete(
      _currentType,
      currency:
          _lastHotelRequest?.currency ?? _lastFlightRequest?.currency,
    ));
  }

  /// Returns from Filters to the previous Results state.
  void backToResults() {
    log('[BOOKING_CUBIT] backToResults');
    if (_previousResultsState != null) {
      emit(_previousResultsState!);
      _previousResultsState = null;
    } else {
      emit(_searchWithClearedAutocomplete(
        _currentType,
        currency:
            _lastHotelRequest?.currency ?? _lastFlightRequest?.currency,
      ));
    }
  }

  /// Goes back to the Search form.
  void backToSearch() {
    log('[BOOKING_CUBIT] backToSearch');
    emit(_searchWithClearedAutocomplete(
      _currentType,
      currency:
          _lastHotelRequest?.currency ?? _lastFlightRequest?.currency,
    ));
  }

  // ── Private helpers ───────────────────────────────────────────

  String _buildSummary({
    required String city,
    required String dateRange,
    required int adults,
  }) =>
      '$city · $dateRange · $adults adult${adults > 1 ? 's' : ''}';
}
