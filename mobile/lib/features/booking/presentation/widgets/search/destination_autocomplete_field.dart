import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';

import '../../../data/models/destination_autocomplete_slot.dart';
import '../../../data/models/destination_suggestion.dart';
import '../../cubit/booking_cubit.dart';
import '../../cubit/booking_state.dart';
import 'booking_autocomplete_scroll.dart';
import 'booking_field_scroll_padding.dart';
import 'booking_search_field_styles.dart';

/// Hotel destination with debounced `GET /bookings/destinations/search`.
class DestinationAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final IconData icon;
  final VoidCallback? onSearchSubmitted;

  const DestinationAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    required this.placeholder,
    this.icon = Icons.search_rounded,
    this.onSearchSubmitted,
  });

  @override
  State<DestinationAutocompleteField> createState() =>
      _DestinationAutocompleteFieldState();
}

class _DestinationAutocompleteFieldState extends State<DestinationAutocompleteField>
    with WidgetsBindingObserver {
  static const _debounceMs = 400;

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
    cubit.onHotelDestinationFieldTextChanged(widget.controller.text);

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (!mounted) return;
      final q = widget.controller.text.trim();
      if (q.length < 2) {
        cubit.clearHotelDestinationSuggestions();
        return;
      }
      cubit.fetchHotelDestinationSuggestions(q);
    });
  }

  void _pick(DestinationSuggestion s) {
    widget.controller.text = s.displayName;
    context.read<BookingCubit>().selectHotelDestination(s);
    _focus.unfocus();
    setState(() {});
  }

  Widget _suggestionsPanel(DestinationAutocompleteSlot slot) {
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
                  final sub = s.searchQuery.trim().isNotEmpty &&
                          s.searchQuery != s.displayName
                      ? s.searchQuery
                      : [
                          if (s.city.isNotEmpty) s.city,
                          if (s.country.isNotEmpty) s.country,
                        ].join(', ');
                  return ListTile(
                    dense: true,
                    title: Text(
                      s.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: sub.isEmpty
                        ? null
                        : Text(
                            sub,
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingCubit, BookingState>(
      listenWhen: (prev, next) {
        if (!_focus.hasFocus) return false;
        DestinationAutocompleteSlot? s(BookingState st) =>
            st is BookingSearch ? st.hotelDestination : null;
        return s(prev) != s(next);
      },
      listener: (_, __) {
        scheduleBookingAutocompleteScrollIntoView(_columnKey);
      },
      child: BlocBuilder<BookingCubit, BookingState>(
        builder: (context, state) {
          final cs = Theme.of(context).colorScheme;
          final accent = context.mapControlAccent;
          final slot = state is BookingSearch ? state.hotelDestination : null;

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
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.placeholder,
                    hintStyle: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Icon(
                      widget.icon,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.65),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: cs.outline.withValues(alpha: 0.35),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: cs.outline.withValues(alpha: 0.35),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: accent,
                        width: 1.5,
                      ),
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) {
                    if (widget.onSearchSubmitted != null) {
                      widget.onSearchSubmitted!();
                    } else {
                      FocusScope.of(context).unfocus();
                    }
                  },
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
