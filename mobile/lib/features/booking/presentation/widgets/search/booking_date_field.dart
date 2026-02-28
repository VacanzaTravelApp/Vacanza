import 'package:flutter/material.dart';

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

  const BookingDateField({
    super.key,
    required this.controller,
    required this.label,
    this.placeholder = 'Select date',
    this.firstDate,
    this.lastDate,
    this.onDateChanged,
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF999999),
            ),
          ),
        ),
        GestureDetector(
          onTap: _pickDate,
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
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _accent,
              onPrimary: Colors.white,
              surface: Colors.white,
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
