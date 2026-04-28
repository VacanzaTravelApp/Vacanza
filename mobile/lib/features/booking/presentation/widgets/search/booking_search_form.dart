import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/vacanza_gradient_button.dart';

import '../../../data/models/accommodation_search_request.dart';
import '../../../data/models/airport_suggestion.dart';
import '../../../data/models/booking_currency.dart';
import '../../../data/models/sort_criteria.dart';
import '../../../data/models/transport_search_request.dart';
import '../../cubit/booking_cubit.dart';
import '../../cubit/booking_state.dart';
import 'adults_stepper.dart';
import 'airport_autocomplete_field.dart';
import 'booking_date_field.dart';
import 'booking_hotel_stay_date_range_dialog.dart';
import 'booking_search_field_styles.dart';
import 'booking_type_toggle.dart';
import 'budget_field.dart';
import 'iata_text_field.dart';
import 'sort_dropdown.dart';

/// UC1.8-MOB6 — Orchestrator form for hotel/flight search.
class BookingSearchForm extends StatefulWidget {
  final BookingType initialType;

  const BookingSearchForm({super.key, required this.initialType});

  @override
  State<BookingSearchForm> createState() => _BookingSearchFormState();
}

class _BookingSearchFormState extends State<BookingSearchForm> {
  late BookingType _type;
  bool _isRestoringFromCubit = false;

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

  // Key to programmatically open return date (flights)
  final _returnKey = GlobalKey<BookingDateFieldState>();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _restoreFromCubit();

    // Only attach the cubit-notifying listener to the hotel query controller.
    // Date and budget controllers trigger rebuilds only through setState in
    // their own change handlers (_pickHotelDateRange, _onDepartureChanged, etc.)
    // to avoid infinite rebuild loops when the cubit emits new states.
    _hotelQueryCtrl.addListener(_onHotelQueryChanged);

    // Lightweight rebuild-only listener for the remaining text controllers so
    // the Search button's enabled-state stays in sync.
    for (final c in _validationControllers) {
      c.addListener(_onValidationFieldChanged);
    }
  }

  /// Controllers whose text changes should only trigger a validation rebuild
  /// (no cubit notification). Date controllers are excluded because their
  /// updates go through [_pickHotelDateRange] / [_onDepartureChanged] which
  /// already call [setState].
  List<TextEditingController> get _validationControllers => [
    _originCtrl,
    _destinationCtrl,
    _budgetCtrl,
  ];

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

  void _onHotelQueryChanged() {
    if (_isRestoringFromCubit || !mounted) return;
    if (_type == BookingType.hotels) {
      context.read<BookingCubit>().onHotelDestinationFieldTextChanged(
        _hotelQueryCtrl.text,
      );
    }
    setState(() {});
  }

  void _onValidationFieldChanged() {
    if (_isRestoringFromCubit || !mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _hotelQueryCtrl.removeListener(_onHotelQueryChanged);
    for (final c in _validationControllers) {
      c.removeListener(_onValidationFieldChanged);
    }
    for (final c in _allControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _restoreFromCubit() {
    final cubit = context.read<BookingCubit>();

    _isRestoringFromCubit = true;
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
          _isRestoringFromCubit = true;
          try {
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
          } finally {
            _isRestoringFromCubit = false;
          }
        });
      }
    }
    _isRestoringFromCubit = false;
  }

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
      final destOk =
          search?.hotelDestination.selected != null ||
          _hotelQueryCtrl.text.trim().length >= 2;
      return destOk &&
          _checkInCtrl.text.isNotEmpty &&
          _checkOutCtrl.text.isNotEmpty;
    }
    final originOk = search?.originAirport.selected != null;
    final destOk = search?.destinationAirport.selected != null;
    return originOk && destOk && _departureCtrl.text.isNotEmpty;
  }

  Widget? _flightSelectionHint(BookingSearch? search) {
    if (search == null) return null;
    final needOrigin =
        _originCtrl.text.trim().isNotEmpty &&
        search.originAirport.selected == null;
    final needDest =
        _destinationCtrl.text.trim().isNotEmpty &&
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
    FocusScope.of(context).unfocus();
    _isRestoringFromCubit = true;
    setState(() => _type = type);
    context.read<BookingCubit>().switchType(type);
    _restoreFromCubit();
    _isRestoringFromCubit = false;
  }

  String _formatHotelIsoDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// Same [CalendarDatePicker] as flights, compact [Dialog]: two taps = check-in + check-out.
  Future<void> _pickHotelDateRange() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(now.year + 2, 12, 31);

    final existingIn =
        _checkInCtrl.text.isNotEmpty
            ? DateTime.tryParse(_checkInCtrl.text)
            : null;
    final existingOut =
        _checkOutCtrl.text.isNotEmpty
            ? DateTime.tryParse(_checkOutCtrl.text)
            : null;

    DateTimeRange? initialRange;
    if (existingIn != null && existingOut != null) {
      var s = DateTime(existingIn.year, existingIn.month, existingIn.day);
      var e = DateTime(existingOut.year, existingOut.month, existingOut.day);
      if (s.isBefore(firstDate)) s = firstDate;
      if (e.isBefore(s) || e.isAfter(lastDate)) {
        e = s.add(const Duration(days: 1));
        if (e.isAfter(lastDate)) e = lastDate;
      }
      initialRange = DateTimeRange(start: s, end: e);
    } else if (_checkInDate != null) {
      final s = DateTime(
        _checkInDate!.year,
        _checkInDate!.month,
        _checkInDate!.day,
      );
      var e = s.add(const Duration(days: 1));
      if (e.isAfter(lastDate)) e = lastDate;
      initialRange = DateTimeRange(
        start: s.isBefore(firstDate) ? firstDate : s,
        end: e,
      );
    }

    if (!context.mounted) return;
    final picked = await showBookingHotelStayDateRange(
      context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialRange: initialRange,
    );

    if (picked == null) return;
    var start = DateTime(
      picked.start.year,
      picked.start.month,
      picked.start.day,
    );
    var end = DateTime(picked.end.year, picked.end.month, picked.end.day);
    if (start.isBefore(firstDate)) start = firstDate;
    if (end.isBefore(start) || !end.isAfter(start)) {
      end = start.add(const Duration(days: 1));
      if (end.isAfter(lastDate)) {
        end = lastDate;
        if (!end.isAfter(start)) {
          start = end.subtract(const Duration(days: 1));
        }
      }
    }
    setState(() {
      _checkInDate = start;
      _checkInCtrl.text = _formatHotelIsoDate(start);
      _checkOutCtrl.text = _formatHotelIsoDate(end);
    });
  }

  void _onDepartureChanged(DateTime date) {
    _departureDate = date;
    if (_returnCtrl.text.isNotEmpty) {
      final ret = DateTime.tryParse(_returnCtrl.text);
      if (ret != null && ret.isBefore(date)) _returnCtrl.clear();
    }
    setState(() {});
  }

  Future<void> _pickFlightDateRange() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(now.year + 2, 12, 31);

    final existingDep =
        _departureCtrl.text.isNotEmpty
            ? DateTime.tryParse(_departureCtrl.text)
            : null;
    final existingRet =
        _returnCtrl.text.isNotEmpty
            ? DateTime.tryParse(_returnCtrl.text)
            : null;

    DateTimeRange? initialRange;
    final depBase = existingDep ?? _departureDate;
    if (existingDep != null && existingRet != null) {
      var s = DateTime(existingDep.year, existingDep.month, existingDep.day);
      var e = DateTime(existingRet.year, existingRet.month, existingRet.day);
      if (s.isBefore(firstDate)) s = firstDate;
      if (!e.isAfter(s)) e = s.add(const Duration(days: 7));
      if (e.isAfter(lastDate)) e = lastDate;
      initialRange = DateTimeRange(start: s, end: e);
    } else if (depBase != null) {
      var s = DateTime(depBase.year, depBase.month, depBase.day);
      if (s.isBefore(firstDate)) s = firstDate;
      final e = s.add(const Duration(days: 7));
      initialRange = DateTimeRange(
        start: s,
        end: e.isAfter(lastDate) ? lastDate : e,
      );
    }

    if (!context.mounted) return;
    final picked = await showBookingFlightDateRange(
      context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialRange: initialRange,
    );

    if (picked == null) return;
    var dep = DateTime(picked.start.year, picked.start.month, picked.start.day);
    var ret = DateTime(picked.end.year, picked.end.month, picked.end.day);
    if (dep.isBefore(firstDate)) dep = firstDate;
    if (!ret.isAfter(dep)) {
      ret = dep.add(const Duration(days: 1));
      if (ret.isAfter(lastDate)) {
        ret = lastDate;
        if (!ret.isAfter(dep)) dep = ret.subtract(const Duration(days: 1));
      }
    }
    setState(() {
      _departureDate = dep;
      _departureCtrl.text = _formatHotelIsoDate(dep);
      _returnCtrl.text = _formatHotelIsoDate(ret);
    });
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
      final query =
          fromSelection.isNotEmpty
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
          returnDate:
              _isRoundTrip && _returnCtrl.text.isNotEmpty
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

  // ── Widgets ───────────────────────────────────────────────────

  Widget _roundTripToggle(BuildContext context) {
    final accent = context.mapControlAccent;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final inactiveBorder = BookingSearchFieldStyles.fieldBorderInactive(
      context,
    );

    return GestureDetector(
      onTap: () {
        setState(() {
          _isRoundTrip = !_isRoundTrip;
          if (!_isRoundTrip) _returnCtrl.clear();
        });
        // Auto-open range picker when enabling round trip with departure set.
        if (_isRoundTrip && _departureCtrl.text.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _pickFlightDateRange();
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color:
              _isRoundTrip
                  ? accent.withValues(alpha: isLight ? 0.08 : 0.14)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                _isRoundTrip ? accent.withValues(alpha: 0.45) : inactiveBorder,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: _isRoundTrip ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: _isRoundTrip ? accent : inactiveBorder,
                  width: 1.5,
                ),
              ),
              child:
                  _isRoundTrip
                      ? const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: Colors.white,
                      )
                      : null,
            ),
            const SizedBox(width: 8),
            Text(
              'Round trip',
              style: BookingSearchFieldStyles.inlineControlLabel(
                context,
              ).copyWith(
                color: _isRoundTrip ? accent : null,
                fontWeight: _isRoundTrip ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchButton(BuildContext context, BookingSearch? search) {
    final enabled = _isValid(search);
    return VacanzaGradientButton(
      label: 'Search ${_type == BookingType.hotels ? 'Hotels' : 'Flights'}',
      icon: Icons.search_rounded,
      enabled: enabled,
      onPressed: enabled ? _onSearch : null,
      minHeight: 54,
      borderRadius: 20,
    );
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<BookingCubit>();
    final search =
        cubit.state is BookingSearch ? cubit.state as BookingSearch : null;
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Type toggle ──────────────────────────────────────────
        BookingTypeToggle(selected: _type, onChanged: _onTypeChanged),
        const SizedBox(height: 24),

        // ── Hotels ──────────────────────────────────────────────
        if (_type == BookingType.hotels)
          KeyedSubtree(
            key: const ValueKey('booking-hotels-form'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle(
                  label: 'Where are you going?',
                  icon: Icons.hotel_rounded,
                ),
                const SizedBox(height: 8),
                _FieldCard(
                  children: [
                    IataTextField(
                      key: const ValueKey('hotel-destination-field'),
                      controller: _hotelQueryCtrl,
                      label: 'Destination',
                      placeholder: 'e.g. Paris or Istanbul',
                      icon: Icons.location_city_rounded,
                      onSubmitted: _onSearch,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionTitle(
                  label: 'When are you staying?',
                  icon: Icons.calendar_month_rounded,
                ),
                const SizedBox(height: 8),
                _FieldCard(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: BookingDateField(
                            key: const ValueKey('hotel-check-in-field'),
                            controller: _checkInCtrl,
                            label: 'Check-in',
                            firstDate: now,
                            onTapOverride: _pickHotelDateRange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: BookingDateField(
                            key: const ValueKey('hotel-check-out-field'),
                            controller: _checkOutCtrl,
                            label: 'Check-out',
                            firstDate:
                                _checkInDate != null
                                    ? _checkInDate!.add(const Duration(days: 1))
                                    : now.add(const Duration(days: 1)),
                            onTapOverride: _pickHotelDateRange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

        // ── Flights ─────────────────────────────────────────────
        if (_type == BookingType.flights)
          KeyedSubtree(
            key: const ValueKey('booking-flights-form'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionTitle(
                  label: 'Where are you flying?',
                  icon: Icons.flight_rounded,
                ),
                const SizedBox(height: 8),
                _FieldCard(
                  children: [
                    AirportAutocompleteField(
                      key: const ValueKey('flight-origin-field'),
                      controller: _originCtrl,
                      label: 'Origin',
                      placeholder: 'e.g. Istanbul or IST',
                      icon: Icons.flight_takeoff_rounded,
                      isOrigin: true,
                    ),
                    const SizedBox(height: 12),
                    AirportAutocompleteField(
                      key: const ValueKey('flight-destination-field'),
                      controller: _destinationCtrl,
                      label: 'Destination',
                      placeholder: 'e.g. Paris or CDG',
                      icon: Icons.flight_land_rounded,
                      isOrigin: false,
                    ),
                    if (_flightSelectionHint(search) != null) ...[
                      const SizedBox(height: 8),
                      _flightSelectionHint(search)!,
                    ],
                    const SizedBox(height: 12),
                    _roundTripToggle(context),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionTitle(
                  label: 'When are you flying?',
                  icon: Icons.calendar_month_rounded,
                ),
                const SizedBox(height: 8),
                _FieldCard(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: BookingDateField(
                            key: const ValueKey('flight-departure-field'),
                            controller: _departureCtrl,
                            label: 'Departure',
                            firstDate: now,
                            onDateChanged:
                                _isRoundTrip ? null : _onDepartureChanged,
                            onTapOverride:
                                _isRoundTrip ? _pickFlightDateRange : null,
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
                              onTapOverride: _pickFlightDateRange,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

        // ── Passengers & Budget ──────────────────────────────────
        const SizedBox(height: 18),
        _SectionTitle(label: 'Passengers & Budget', icon: Icons.people_rounded),
        const SizedBox(height: 8),
        _FieldCard(
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
                    onCurrencyChanged:
                        (c) => context.read<BookingCubit>().setCurrency(c),
                    label:
                        _type == BookingType.hotels
                            ? 'Budget per night'
                            : 'Budget (Optional)',
                    helperText:
                        _type == BookingType.hotels
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
        ),

        const SizedBox(height: 28),
        _searchButton(context, search),
      ],
    );
  }
}

// ── Section title with gradient icon badge ────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionTitle({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final accent = context.mapControlAccent;
    final t = context.vacanzaTokens;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final gradientEnd =
        Color.lerp(
          accent,
          isLight ? const Color(0xFFFF8C00) : Colors.white,
          isLight ? 0.22 : 0.20,
        )!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accent, gradientEnd],
            ),
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.30),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: t.textMain,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

// ── Section field card ────────────────────────────────────────────────────────

class _FieldCard extends StatelessWidget {
  final List<Widget> children;

  const _FieldCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor =
        isLight ? const Color(0xFFE2E8F0) : cs.outline.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient:
            isLight
                ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFF8FAFC)],
                )
                : null,
        color:
            isLight ? null : cs.surfaceContainerHighest.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow:
            isLight
                ? [
                  const BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                  const BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ]
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
