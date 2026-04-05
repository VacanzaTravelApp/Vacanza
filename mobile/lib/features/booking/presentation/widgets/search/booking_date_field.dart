import 'package:flutter/material.dart';

import 'booking_search_field_styles.dart';

/// Reusable read-only date field that opens a date picker on tap.
///
/// Exposes [openPicker] so the parent can programmatically trigger it
/// (e.g., auto-open check-out after check-in selection).
class BookingDateField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String placeholder;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime>? onDateChanged;
  final Future<void> Function()? onTapOverride;

  const BookingDateField({
    super.key,
    required this.controller,
    required this.label,
    this.placeholder = 'Select date',
    this.firstDate,
    this.lastDate,
    this.onDateChanged,
    this.onTapOverride,
  });

  @override
  State<BookingDateField> createState() => BookingDateFieldState();
}

class BookingDateFieldState extends State<BookingDateField> {
  static const _accent = Color(0xFF0096FF);

  /// Programmatically opens the date picker.
  Future<void> openPicker() => _pickDate();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            widget.label,
            style: BookingSearchFieldStyles.fieldLabel,
          ),
        ),
        GestureDetector(
          onTap: () async {
            FocusScope.of(context).unfocus();
            if (widget.onTapOverride != null) {
              await widget.onTapOverride!();
            } else {
              await _pickDate();
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              controller: widget.controller,
              readOnly: true,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: const TextStyle(
                  color: Color(0xFFBBBBBB),
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: Color(0xFFAAAAAA),
                ),
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
                  borderSide: const BorderSide(color: _accent, width: 1.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final earliest = widget.firstDate ?? now;
    final latest = widget.lastDate ?? DateTime(now.year + 2);

    DateTime initial = earliest;
    if (widget.controller.text.isNotEmpty) {
      final parsed = DateTime.tryParse(widget.controller.text);
      if (parsed != null &&
          !parsed.isBefore(earliest) &&
          !parsed.isAfter(latest)) {
        initial = parsed;
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: earliest,
      lastDate: latest,
      builder: (ctx, child) {
        final baseTheme = Theme.of(ctx);
        return Theme(
          data: baseTheme.copyWith(
            colorScheme: baseTheme.colorScheme.copyWith(
              primary: _accent,
              onPrimary: Colors.white,
            ),
            datePickerTheme: baseTheme.datePickerTheme.copyWith(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              headerBackgroundColor: _accent,
              headerForegroundColor: Colors.white,
              backgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      widget.controller.text = _format(picked);
      widget.onDateChanged?.call(picked);
    }
  }

  String _format(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
