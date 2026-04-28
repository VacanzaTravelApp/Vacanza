import 'package:flutter/material.dart';

import 'package:mobile/core/theme/app_theme.dart';

import 'booking_date_picker_theme.dart';
import 'booking_search_field_styles.dart';

/// Reusable read-only date field that opens a date picker on tap.
///
/// [controller] stores the ISO-8601 date string (YYYY-MM-DD) for API use;
/// a separate internal controller shows it as a human-friendly label
/// (e.g., "Mon, Apr 27").
///
/// Exposes [openPicker] so the parent can programmatically trigger it.
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
  late final TextEditingController _displayCtrl;

  @override
  void initState() {
    super.initState();
    _displayCtrl = TextEditingController(text: _toDisplay(widget.controller.text));
    widget.controller.addListener(_syncDisplay);
  }

  @override
  void didUpdateWidget(covariant BookingDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncDisplay);
      widget.controller.addListener(_syncDisplay);
      _syncDisplay();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncDisplay);
    _displayCtrl.dispose();
    super.dispose();
  }

  void _syncDisplay() {
    if (!mounted) return;
    final d = _toDisplay(widget.controller.text);
    if (_displayCtrl.text != d) {
      setState(() {
        _displayCtrl.text = d;
      });
    }
  }

  /// Parses ISO-8601 (YYYY-MM-DD) into "Mon, Apr 27".
  String _toDisplay(String iso) {
    if (iso.isEmpty) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  Future<void> openPicker() => _pickDate();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    final hasPick = _displayCtrl.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            widget.label,
            style: BookingSearchFieldStyles.fieldLabel(context),
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
              controller: _displayCtrl,
              readOnly: true,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: hasPick ? accent : cs.onSurface,
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
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: hasPick ? accent : cs.onSurfaceVariant,
                  ),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
                filled: true,
                fillColor: hasPick
                    ? accent.withValues(alpha: 0.07)
                    : BookingSearchFieldStyles.fieldFill(context),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: BookingSearchFieldStyles.fieldBorderInactive(context),
                    width: 1.2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: hasPick
                        ? accent.withValues(alpha: 0.45)
                        : BookingSearchFieldStyles.fieldBorderInactive(context),
                    width: hasPick ? 1.5 : 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: accent, width: 1.8),
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
      builder: (ctx, child) => buildBookingDatePickerDialog(ctx, child),
    );

    if (picked != null) {
      widget.controller.text = _formatIso(picked);
      widget.onDateChanged?.call(picked);
    }
  }

  String _formatIso(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
