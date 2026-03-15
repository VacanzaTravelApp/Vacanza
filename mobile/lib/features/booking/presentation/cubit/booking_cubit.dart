import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/accommodation_search_request.dart';
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
    log('[BOOKING_CUBIT] switchType → $type');
    emit(BookingSearch(type: type));
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
      emit(BookingError(type: BookingType.hotels, message: e.toString()));
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
      emit(BookingError(type: BookingType.flights, message: e.toString()));
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
    emit(BookingSearch(type: _currentType));
  }

  /// Returns from Filters to the previous Results state.
  void backToResults() {
    log('[BOOKING_CUBIT] backToResults');
    if (_previousResultsState != null) {
      emit(_previousResultsState!);
      _previousResultsState = null;
    } else {
      emit(BookingSearch(type: _currentType));
    }
  }

  /// Goes back to the Search form.
  void backToSearch() {
    log('[BOOKING_CUBIT] backToSearch');
    emit(BookingSearch(type: _currentType));
  }

  // ── Private helpers ───────────────────────────────────────────

  String _buildSummary({
    required String city,
    required String dateRange,
    required int adults,
  }) =>
      '$city · $dateRange · $adults adult${adults > 1 ? 's' : ''}';
}
