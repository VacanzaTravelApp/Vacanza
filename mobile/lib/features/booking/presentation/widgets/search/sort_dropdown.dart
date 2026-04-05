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

  static const _accent = Color(0xFF0096FF);

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            'Sort by',
            style: BookingSearchFieldStyles.fieldLabel,
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
                    style: BookingSearchFieldStyles.dropdownMenuItem
                        .copyWith(fontSize: 13),
                  ),
                ),
              )
              .toList(),
          icon: const Icon(
            Icons.swap_vert_rounded,
            size: 18,
            color: Color(0xFFAAAAAA),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
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
              borderSide: const BorderSide(color: _accent, width: 1.5),
            ),
          ),
          dropdownColor: Colors.white,
          style: BookingSearchFieldStyles.dropdownMenuItem.copyWith(
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
