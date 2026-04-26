import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/airport_autocomplete_slot.dart';
import '../../../data/models/airport_suggestion.dart';
import '../../cubit/booking_cubit.dart';
import '../../cubit/booking_state.dart';
import 'booking_autocomplete_scroll.dart';
import 'booking_field_scroll_padding.dart';
import 'package:mobile/core/theme/app_theme.dart';

import 'booking_search_field_styles.dart';

/// Flight origin/destination with debounced `GET /bookings/airports/search`.
class AirportAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final IconData icon;
  final bool isOrigin;

  const AirportAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    required this.placeholder,
    required this.icon,
    required this.isOrigin,
  });

  @override
  State<AirportAutocompleteField> createState() =>
      _AirportAutocompleteFieldState();
}

class _AirportAutocompleteFieldState extends State<AirportAutocompleteField>
    with WidgetsBindingObserver {
  static const _debounceMs = 300;

  final FocusNode _focus = FocusNode();
  final GlobalKey _columnKey = GlobalKey();
  Timer? _debounce;

  void _onFocusChanged() {
    setState(() {});
    if (_focus.hasFocus) {
      scheduleBookingAutocompleteScrollIntoView(_columnKey);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_onControllerChanged);
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    _focus.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (_focus.hasFocus) {
      scheduleBookingAutocompleteScrollIntoView(_columnKey);
    }
  }

  void _onControllerChanged() {
    final cubit = context.read<BookingCubit>();
    final text = widget.controller.text;
    if (widget.isOrigin) {
      cubit.onOriginFieldTextChanged(text);
    } else {
      cubit.onDestinationFieldTextChanged(text);
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (!mounted) return;
      final q = text.trim();
      if (q.length < 2) {
        if (widget.isOrigin) {
          cubit.clearOriginAirportSuggestions();
        } else {
          cubit.clearDestinationAirportSuggestions();
        }
        return;
      }
      if (widget.isOrigin) {
        cubit.fetchOriginAirportSuggestions(q);
      } else {
        cubit.fetchDestinationAirportSuggestions(q);
      }
    });
  }

  void _pick(AirportSuggestion s) {
    widget.controller.text = s.dropdownLabel;
    final cubit = context.read<BookingCubit>();
    if (widget.isOrigin) {
      cubit.selectOriginAirport(s);
    } else {
      cubit.selectDestinationAirport(s);
    }
    _focus.unfocus();
    setState(() {});
  }

  Widget _suggestionsPanel(AirportAutocompleteSlot slot) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: slot.loadingSuggestions && slot.suggestions.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: slot.suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = slot.suggestions[i];
                  final subtitle = [
                    if (s.city.isNotEmpty) s.city,
                    if (s.country.isNotEmpty) s.country,
                  ].join(', ');
                  return ListTile(
                    dense: true,
                    title: Text(
                      s.dropdownLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: subtitle.isEmpty
                        ? null
                        : Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                    onTap: () => _pick(s),
                  );
                },
              ),
      ),
    );
  }

  AirportAutocompleteSlot? _slot(BookingState st) {
    if (st is! BookingSearch) return null;
    return widget.isOrigin ? st.originAirport : st.destinationAirport;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingCubit, BookingState>(
      listenWhen: (prev, next) {
        if (!_focus.hasFocus) return false;
        return _slot(prev) != _slot(next);
      },
      listener: (_, __) {
        scheduleBookingAutocompleteScrollIntoView(_columnKey);
      },
      child: BlocBuilder<BookingCubit, BookingState>(
        builder: (context, state) {
          final cs = Theme.of(context).colorScheme;
          final accent = context.mapControlAccent;
          final slot = _slot(state);

          Widget? panel;
          if (_focus.hasFocus &&
              slot != null &&
              (slot.loadingSuggestions || slot.suggestions.isNotEmpty)) {
            panel = _suggestionsPanel(slot);
          }

          return KeyedSubtree(
            key: _columnKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 6),
                  child: Text(
                    widget.label,
                    style: BookingSearchFieldStyles.fieldLabel(context),
                  ),
                ),
                TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  scrollPadding: bookingFieldScrollPadding(context),
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.placeholder,
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.60),
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 14, right: 10),
                      child: Icon(
                        widget.icon,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                    filled: true,
                    fillColor: BookingSearchFieldStyles.fieldFill(context),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: BookingSearchFieldStyles.fieldBorderInactive(
                          context,
                        ),
                        width: 1.2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: BookingSearchFieldStyles.fieldBorderInactive(
                          context,
                        ),
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: accent, width: 1.8),
                    ),
                  ),
                ),
                if (slot != null &&
                    slot.suggestionError != null &&
                    slot.suggestionError!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      slot.suggestionError!,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.error,
                      ),
                    ),
                  ),
                if (panel != null) ...[
                  const SizedBox(height: 6),
                  panel,
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
