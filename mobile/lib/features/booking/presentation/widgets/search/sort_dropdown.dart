import 'package:flutter/material.dart';

import '../../../data/models/sort_criteria.dart';
import '../../cubit/booking_state.dart';
import 'booking_search_field_styles.dart';

/// Sort criteria dropdown showing type-appropriate options.
class SortDropdown extends StatelessWidget {
  final SortCriteria value;
  final BookingType bookingType;
  final ValueChanged<SortCriteria> onChanged;

  const SortDropdown({
    super.key,
    required this.value,
    required this.bookingType,
    required this.onChanged,
  });

  static const _labels = {
    SortCriteria.priceAsc: 'Price: Low to High',
    SortCriteria.priceDesc: 'Price: High to Low',
    SortCriteria.ratingDesc: 'Rating: High to Low',
  };

  List<SortCriteria> get _options => bookingType == BookingType.hotels
      ? SortCriteria.values
      : [SortCriteria.priceAsc, SortCriteria.priceDesc];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = bookingAccentColor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            'Sort by',
            style: BookingSearchFieldStyles.fieldLabel(context),
          ),
        ),
        DropdownButtonFormField<SortCriteria>(
          initialValue: _options.contains(value) ? value : _options.first,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          items: _options
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    _labels[s]!,
                    style: BookingSearchFieldStyles.dropdownMenuItem(context)
                        .copyWith(fontSize: 13),
                  ),
                ),
              )
              .toList(),
          icon: Icon(
            Icons.swap_vert_rounded,
            size: 18,
            color: cs.onSurfaceVariant,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: BookingSearchFieldStyles.fieldFill(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: BookingSearchFieldStyles.fieldBorderInactive(context),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: BookingSearchFieldStyles.fieldBorderInactive(context),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: accent, width: 1.5),
            ),
          ),
          dropdownColor: cs.surface,
          style: BookingSearchFieldStyles.dropdownMenuItem(context).copyWith(
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
