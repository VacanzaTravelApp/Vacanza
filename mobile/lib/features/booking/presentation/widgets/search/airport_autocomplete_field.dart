import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/airport_autocomplete_slot.dart';
import '../../../data/models/airport_suggestion.dart';
import '../../cubit/booking_cubit.dart';
import 'booking_field_scroll_padding.dart';
import '../../cubit/booking_state.dart';

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

class _AirportAutocompleteFieldState extends State<AirportAutocompleteField> {
  static const _accent = Color(0xFF0096FF);
  static const _debounceMs = 300;

  final FocusNode _focus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    _focus.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      buildWhen: (prev, cur) {
        AirportAutocompleteSlot? slot(BookingState st) {
          if (st is! BookingSearch) return null;
          return widget.isOrigin ? st.originAirport : st.destinationAirport;
        }

        return slot(prev) != slot(cur);
      },
      builder: (context, state) {
        final slot = state is BookingSearch
            ? (widget.isOrigin
                ? state.originAirport
                : state.destinationAirport)
            : null;

        final showPanel = _focus.hasFocus &&
            slot != null &&
            (slot.loadingSuggestions || slot.suggestions.isNotEmpty);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF999999),
                ),
              ),
            ),
            TextField(
              controller: widget.controller,
              focusNode: _focus,
              scrollPadding: bookingFieldScrollPadding(context),
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: const TextStyle(
                  color: Color(0xFFBBBBBB),
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon:
                    Icon(widget.icon, size: 20, color: const Color(0xFFAAAAAA)),
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: _accent,
                    width: 1.5,
                  ),
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB00020),
                  ),
                ),
              ),
            if (showPanel) ...[
              const SizedBox(height: 6),
              Material(
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
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
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
              ),
            ],
          ],
        );
      },
    );
  }
}
