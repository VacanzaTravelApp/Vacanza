import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/theme/app_theme.dart';

import '../../../data/models/accommodation_search_request.dart';
import '../../../data/models/airport_suggestion.dart';
import '../../../data/models/booking_currency.dart';
import '../../../data/models/sort_criteria.dart';
import '../../../data/models/transport_search_request.dart';
import '../../cubit/booking_cubit.dart';
import '../../cubit/booking_state.dart';
import 'adults_stepper.dart';
import 'booking_date_field.dart';
import 'booking_type_toggle.dart';
import 'budget_field.dart';
import 'airport_autocomplete_field.dart';
import 'destination_autocomplete_field.dart';
import 'sort_dropdown.dart';
import 'booking_search_field_styles.dart';

/// UC1.8-MOB6 — Orchestrator form for hotel/flight search.
class BookingSearchForm extends StatefulWidget {
  final BookingType initialType;

  const BookingSearchForm({super.key, required this.initialType});

  @override
  State<BookingSearchForm> createState() => _BookingSearchFormState();
}

class _BookingSearchFormState extends State<BookingSearchForm> {
  late BookingType _type;

  // Hotels
  final _hotelQueryCtrl = TextEditingController();
  final _checkInCtrl = TextEditingController();
  final _checkOutCtrl = TextEditingController();

  // Flights
  final _originCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();
  final _departureCtrl = TextEditingController();
  final _returnCtrl = TextEditingController();
  bool _isRoundTrip = false;

  // Shared
  final _budgetCtrl = TextEditingController();
  int _adults = 1;
  SortCriteria _sort = SortCriteria.priceAsc;

  // Cross-field date tracking
  DateTime? _checkInDate;
  DateTime? _departureDate;

  // Keys to programmatically open pickers
  final _checkOutKey = GlobalKey<BookingDateFieldState>();
  final _returnKey = GlobalKey<BookingDateFieldState>();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _restoreFromCubit();
    for (final c in _allControllers) {
      c.addListener(_onFieldChanged);
    }
  }

  List<TextEditingController> get _allControllers => [
        _hotelQueryCtrl,
        _checkInCtrl,
        _checkOutCtrl,
        _originCtrl,
        _destinationCtrl,
        _departureCtrl,
        _returnCtrl,
        _budgetCtrl,
      ];

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    for (final c in _allControllers) {
      c.removeListener(_onFieldChanged);
      c.dispose();
    }
    super.dispose();
  }

  void _restoreFromCubit() {
    final cubit = context.read<BookingCubit>();

    if (_type == BookingType.hotels) {
      final req = cubit.lastHotelRequest;
      if (req != null) {
        cubit.setCurrency(req.currency);
        _hotelQueryCtrl.text = req.query;
        _checkInCtrl.text = req.checkInDate;
        _checkOutCtrl.text = req.checkOutDate;
        _adults = req.adults;
        _budgetCtrl.text = req.budget?.toString() ?? '';
        _sort = req.sortBy ?? SortCriteria.priceAsc;
        _checkInDate = DateTime.tryParse(req.checkInDate);
      }
    } else {
      final req = cubit.lastFlightRequest;
      if (req != null) {
        cubit.setCurrency(req.currency);
        _departureCtrl.text = req.departureDate;
        _returnCtrl.text = req.returnDate ?? '';
        _isRoundTrip = req.returnDate != null;
        _adults = req.adults;
        _budgetCtrl.text = req.budget?.toString() ?? '';
        _sort = req.sortBy ?? SortCriteria.priceAsc;
        _departureDate = DateTime.tryParse(req.departureDate);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final c = context.read<BookingCubit>();
          final r = c.lastFlightRequest;
          if (r == null) return;
          if (c.state is! BookingSearch) return;
          if (r.origin.trim().isNotEmpty) {
            final o = _suggestionFromResolvedId(r.origin);
            c.selectOriginAirport(o);
            _originCtrl.text = o.dropdownLabel;
          }
          if (r.destination.trim().isNotEmpty) {
            final d = _suggestionFromResolvedId(r.destination);
            c.selectDestinationAirport(d);
            _destinationCtrl.text = d.dropdownLabel;
          }
        });
      }
    }
  }

  /// Rebuilds a minimal [AirportSuggestion] from a stored request id (TASK-10 restore).
  AirportSuggestion _suggestionFromResolvedId(String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      return const AirportSuggestion(name: '', city: '', country: '');
    }
    final upper = t.toUpperCase();
    final asIata = RegExp(r'^[A-Z]{3}$').hasMatch(upper);
    return AirportSuggestion(
      iataCode: asIata ? upper : null,
      kgmid: asIata ? null : t,
      name: '',
      city: '',
      country: '',
    );
  }

  bool _isValid(BookingSearch? search) {
    if (_type == BookingType.hotels) {
      final destOk = search?.hotelDestination.selected != null ||
          _hotelQueryCtrl.text.trim().length >= 2;
      return destOk &&
          _checkInCtrl.text.isNotEmpty &&
          _checkOutCtrl.text.isNotEmpty;
    }
    final originOk = search?.originAirport.selected != null;
    final destOk = search?.destinationAirport.selected != null;
    return originOk && destOk && _departureCtrl.text.isNotEmpty;
  }

  /// Shown when the user typed in an airport field but did not pick a suggestion (TASK-10).
  Widget? _flightSelectionHint(BookingSearch? search) {
    if (search == null) return null;
    final needOrigin =
        _originCtrl.text.trim().isNotEmpty && search.originAirport.selected == null;
    final needDest = _destinationCtrl.text.trim().isNotEmpty &&
        search.destinationAirport.selected == null;
    if (!needOrigin && !needDest) return null;
    return Text(
      'Pick origin and destination from the suggestions list.',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.orange.shade800,
      ),
    );
  }

  void _onTypeChanged(BookingType type) {
    if (type == _type) return;
    setState(() => _type = type);
    context.read<BookingCubit>().switchType(type);
    _restoreFromCubit();
  }

  // ── Cross-field date logic ────────────────────────────────────

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _pickHotelDateRange() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = DateTime(now.year + 2);

    DateTimeRange? initialRange;
    final existingCheckIn =
        _checkInCtrl.text.isNotEmpty ? DateTime.tryParse(_checkInCtrl.text) : null;
    final existingCheckOut =
        _checkOutCtrl.text.isNotEmpty ? DateTime.tryParse(_checkOutCtrl.text) : null;

    if (existingCheckIn != null && existingCheckOut != null) {
      initialRange = DateTimeRange(start: existingCheckIn, end: existingCheckOut);
    } else {
      final start = _checkInDate != null && _checkInDate!.isAfter(firstDate)
          ? _checkInDate!
          : firstDate;
      final end = start.add(const Duration(days: 1));
      initialRange = DateTimeRange(start: start, end: end);
    }

    final accent = context.mapControlAccent;
    final surface = Theme.of(context).colorScheme.surface;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: initialRange,
      builder: (ctx, child) {
        final baseTheme = Theme.of(ctx);
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: baseTheme.colorScheme.copyWith(
              primary: accent,
              onPrimary: Colors.white,
            ),
            datePickerTheme: baseTheme.datePickerTheme.copyWith(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              headerBackgroundColor: accent,
              headerForegroundColor: Colors.white,
              backgroundColor: surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final start = picked.start;
      final end = picked.end;
      _checkInDate = start;
      _checkInCtrl.text = _formatDate(start);
      _checkOutCtrl.text = _formatDate(end);
      _onCheckInChanged(start);
      setState(() {});
    }
  }

  void _onCheckInChanged(DateTime date) {
    _checkInDate = date;
    if (_checkOutCtrl.text.isNotEmpty) {
      final checkOut = DateTime.tryParse(_checkOutCtrl.text);
      if (checkOut != null && !checkOut.isAfter(date)) {
        _checkOutCtrl.clear();
      }
    }
    setState(() {});

    // Auto-open check-out if empty
    if (_checkOutCtrl.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkOutKey.currentState?.openPicker();
      });
    }
  }

  void _onDepartureChanged(DateTime date) {
    _departureDate = date;
    if (_returnCtrl.text.isNotEmpty) {
      final ret = DateTime.tryParse(_returnCtrl.text);
      if (ret != null && ret.isBefore(date)) {
        _returnCtrl.clear();
      }
    }
    setState(() {});

    // Auto-open return if round-trip and empty
    if (_isRoundTrip && _returnCtrl.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _returnKey.currentState?.openPicker();
      });
    }
  }

  void _onSearch() {
    final cubit = context.read<BookingCubit>();
    final search =
        cubit.state is BookingSearch ? cubit.state as BookingSearch : null;
    if (!_isValid(search)) return;

    final budget = BudgetField.parse(_budgetCtrl.text);
    final currency = BookingCurrencies.normalize(search?.currency);

    if (_type == BookingType.hotels) {
      final fromSelection =
          search?.hotelDestination.selected?.searchQuery.trim() ?? '';
      final query = fromSelection.isNotEmpty
          ? fromSelection
          : _hotelQueryCtrl.text.trim();
      cubit.searchHotels(
        AccommodationSearchRequest(
          query: query,
          checkInDate: _checkInCtrl.text,
          checkOutDate: _checkOutCtrl.text,
          adults: _adults,
          budget: budget,
          currency: currency,
          sortBy: _sort,
        ),
      );
    } else {
      final originSel = search!.originAirport.selected!;
      final destSel = search.destinationAirport.selected!;
      cubit.searchFlights(
        TransportSearchRequest(
          origin: originSel.resolvedSearchId,
          destination: destSel.resolvedSearchId,
          departureDate: _departureCtrl.text,
          returnDate: _isRoundTrip && _returnCtrl.text.isNotEmpty
              ? _returnCtrl.text
              : null,
          adults: _adults,
          budget: budget,
          currency: currency,
          sortBy: _sort,
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<BookingCubit>();
    final search =
        cubit.state is BookingSearch ? cubit.state as BookingSearch : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BookingTypeToggle(
          selected: _type,
          onChanged: _onTypeChanged,
        ),
        const SizedBox(height: 20),
        if (_type == BookingType.hotels) ..._hotelFields(context),
        if (_type == BookingType.flights) ..._flightFields(context, search),
        const SizedBox(height: 12),
        _sharedFields(context, search),
        const SizedBox(height: 28),
        _searchButton(context, search),
      ],
    );
  }

  List<Widget> _hotelFields(BuildContext context) {
    final now = DateTime.now();
    return [
      DestinationAutocompleteField(
        controller: _hotelQueryCtrl,
        label: 'Destination',
        placeholder: 'e.g. Paris or Istanbul',
        icon: Icons.location_city_rounded,
        onSearchSubmitted: _onSearch,
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: BookingDateField(
              controller: _checkInCtrl,
              label: 'Check-in',
              firstDate: now,
              onDateChanged: _onCheckInChanged,
              onTapOverride: _pickHotelDateRange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: BookingDateField(
              key: _checkOutKey,
              controller: _checkOutCtrl,
              label: 'Check-out',
              firstDate: _checkInDate != null
                  ? _checkInDate!.add(const Duration(days: 1))
                  : now.add(const Duration(days: 1)),
              onDateChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _flightFields(BuildContext context, BookingSearch? search) {
    final now = DateTime.now();
    final hint = _flightSelectionHint(search);
    return [
      AirportAutocompleteField(
        controller: _originCtrl,
        label: 'Origin',
        placeholder: 'e.g. Istanbul or IST',
        icon: Icons.flight_takeoff_rounded,
        isOrigin: true,
      ),
      const SizedBox(height: 12),
      AirportAutocompleteField(
        controller: _destinationCtrl,
        label: 'Destination',
        placeholder: 'e.g. Paris or CDG',
        icon: Icons.flight_land_rounded,
        isOrigin: false,
      ),
      if (hint != null) ...[
        const SizedBox(height: 8),
        hint,
      ],
      const SizedBox(height: 12),

      // Round-trip toggle
      _roundTripToggle(context),
      const SizedBox(height: 12),

      // Date row
      Row(
        children: [
          Expanded(
            child: BookingDateField(
              controller: _departureCtrl,
              label: 'Departure',
              firstDate: now,
              onDateChanged: _onDepartureChanged,
            ),
          ),
          if (_isRoundTrip) ...[
            const SizedBox(width: 12),
            Expanded(
              child: BookingDateField(
                key: _returnKey,
                controller: _returnCtrl,
                label: 'Return',
                firstDate: _departureDate ?? now,
                onDateChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ],
      ),
    ];
  }

  Widget _roundTripToggle(BuildContext context) {
    final accent = context.mapControlAccent;
    final outline = Theme.of(context).colorScheme.outline;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isRoundTrip = !_isRoundTrip;
          if (!_isRoundTrip) _returnCtrl.clear();
        });
      },
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _isRoundTrip ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _isRoundTrip ? accent : outline.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: _isRoundTrip
                ? const Icon(Icons.check_rounded,
                    size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            'Round trip',
            style: BookingSearchFieldStyles.inlineControlLabel(context),
          ),
        ],
      ),
    );
  }

  Widget _sharedFields(BuildContext context, BookingSearch? search) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AdultsStepper(
                value: _adults,
                onChanged: (v) => setState(() => _adults = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BudgetField(
                controller: _budgetCtrl,
                currencyCode: BookingCurrencies.normalize(search?.currency),
                onCurrencyChanged: (c) =>
                    context.read<BookingCubit>().setCurrency(c),
                label: _type == BookingType.hotels
                    ? 'Budget per night'
                    : 'Budget (Optional)',
                helperText: _type == BookingType.hotels
                    ? 'Max nightly price. Leave empty for no limit.'
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SortDropdown(
          value: _sort,
          bookingType: _type,
          onChanged: (v) => setState(() => _sort = v),
        ),
      ],
    );
  }

  Widget _searchButton(BuildContext context, BookingSearch? search) {
    final enabled = _isValid(search);
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    final gradientColors = context.mapControlActiveGradientColors;
    return GestureDetector(
      onTap: enabled ? _onSearch : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                )
              : null,
          color: enabled ? null : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 20,
              color: enabled ? Colors.white : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              'Search ${_type == BookingType.hotels ? 'Hotels' : 'Flights'}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.white : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
