import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/accommodation_search_request.dart';
import '../../../data/models/sort_criteria.dart';
import '../../../data/models/transport_search_request.dart';
import '../../cubit/booking_cubit.dart';
import '../../cubit/booking_state.dart';
import 'adults_stepper.dart';
import 'booking_date_field.dart';
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
  static const _accent = Color(0xFF0096FF);

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
        _originCtrl.text = req.origin;
        _destinationCtrl.text = req.destination;
        _departureCtrl.text = req.departureDate;
        _returnCtrl.text = req.returnDate ?? '';
        _isRoundTrip = req.returnDate != null;
        _adults = req.adults;
        _budgetCtrl.text = req.budget?.toString() ?? '';
        _sort = req.sortBy ?? SortCriteria.priceAsc;
        _departureDate = DateTime.tryParse(req.departureDate);
      }
    }
  }

  bool get _isValid {
    if (_type == BookingType.hotels) {
      return _hotelQueryCtrl.text.trim().isNotEmpty &&
          _checkInCtrl.text.isNotEmpty &&
          _checkOutCtrl.text.isNotEmpty;
    }
    return _originCtrl.text.length == 3 &&
        _destinationCtrl.text.length == 3 &&
        _departureCtrl.text.isNotEmpty;
  }

  void _onTypeChanged(BookingType type) {
    if (type == _type) return;
    setState(() => _type = type);
    context.read<BookingCubit>().switchType(type);
    _restoreFromCubit();
  }

  // ── Cross-field date logic ────────────────────────────────────

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
    if (!_isValid) return;

    final cubit = context.read<BookingCubit>();
    final budget = BudgetField.parse(_budgetCtrl.text);

    if (_type == BookingType.hotels) {
      cubit.searchHotels(
        AccommodationSearchRequest(
          query: _hotelQueryCtrl.text.trim(),
          checkInDate: _checkInCtrl.text,
          checkOutDate: _checkOutCtrl.text,
          adults: _adults,
          budget: budget,
          sortBy: _sort,
        ),
      );
    } else {
      cubit.searchFlights(
        TransportSearchRequest(
          origin: _originCtrl.text,
          destination: _destinationCtrl.text,
          departureDate: _departureCtrl.text,
          returnDate: _isRoundTrip && _returnCtrl.text.isNotEmpty
              ? _returnCtrl.text
              : null,
          adults: _adults,
          budget: budget,
          sortBy: _sort,
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BookingTypeToggle(
          selected: _type,
          onChanged: _onTypeChanged,
        ),
        const SizedBox(height: 20),
        if (_type == BookingType.hotels) ..._hotelFields(),
        if (_type == BookingType.flights) ..._flightFields(),
        const SizedBox(height: 12),
        _sharedFields(),
        const SizedBox(height: 28),
        _searchButton(),
      ],
    );
  }

  List<Widget> _hotelFields() {
    final now = DateTime.now();
    return [
      TextField(
        controller: _hotelQueryCtrl,
        decoration: const InputDecoration(
          labelText: 'Search hotels',
          hintText: 'e.g. Hotels in Paris, Bali resorts',
          prefixIcon: Icon(Icons.search_rounded),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _onSearch(),
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

  List<Widget> _flightFields() {
    final now = DateTime.now();
    return [
      IataTextField(
        controller: _originCtrl,
        label: 'Origin (IATA)',
        placeholder: 'e.g. IST',
        icon: Icons.flight_takeoff_rounded,
      ),
      const SizedBox(height: 12),
      IataTextField(
        controller: _destinationCtrl,
        label: 'Destination (IATA)',
        placeholder: 'e.g. PAR',
        icon: Icons.search_rounded,
      ),
      const SizedBox(height: 12),

      // Round-trip toggle
      _roundTripToggle(),
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

  Widget _roundTripToggle() {
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
              color: _isRoundTrip ? _accent : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _isRoundTrip ? _accent : const Color(0xFFCCCCCC),
                width: 1.5,
              ),
            ),
            child: _isRoundTrip
                ? const Icon(Icons.check_rounded,
                    size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          const Text(
            'Round trip',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sharedFields() {
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

  Widget _searchButton() {
    final enabled = _isValid;
    return GestureDetector(
      onTap: enabled ? _onSearch : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF0096FF), Color(0xFF00C6FF)],
                )
              : null,
          color: enabled ? null : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(20),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.3),
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
              color: enabled ? Colors.white : const Color(0xFFAAAAAA),
            ),
            const SizedBox(width: 8),
            Text(
              'Search ${_type == BookingType.hotels ? 'Hotels' : 'Flights'}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.white : const Color(0xFFAAAAAA),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
