import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

import 'booking_date_picker_theme.dart' as t show buildBookingDatePickerDialog;

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

enum _StayDateStep { checkIn, checkOut }

/// Hotel check-in / check-out in one flow.
Future<DateTimeRange?> showBookingHotelStayDateRange(
  BuildContext context, {
  required DateTime firstDate,
  required DateTime lastDate,
  DateTimeRange? initialRange,
}) {
  return _showDateRangeDialog(
    context,
    firstDate: firstDate,
    lastDate: lastDate,
    initialRange: initialRange,
    title: 'Your stay',
    startLabel: 'Check-in',
    endLabel: 'Check-out',
    durationWord: 'night',
  );
}

/// Flight departure / return in one flow — same UX as hotel stay picker.
Future<DateTimeRange?> showBookingFlightDateRange(
  BuildContext context, {
  required DateTime firstDate,
  required DateTime lastDate,
  DateTimeRange? initialRange,
}) {
  return _showDateRangeDialog(
    context,
    firstDate: firstDate,
    lastDate: lastDate,
    initialRange: initialRange,
    title: 'Your trip',
    startLabel: 'Departure',
    endLabel: 'Return',
    durationWord: 'day',
  );
}

Future<DateTimeRange?> _showDateRangeDialog(
  BuildContext context, {
  required DateTime firstDate,
  required DateTime lastDate,
  required String title,
  required String startLabel,
  required String endLabel,
  required String durationWord,
  DateTimeRange? initialRange,
}) {
  final f = _dateOnly(firstDate);
  final l = _dateOnly(lastDate);
  return showDialog<DateTimeRange>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      return t.buildBookingDatePickerDialog(
        ctx,
        _DateRangeContent(
          firstDate: f,
          lastDate: l,
          initialRange: initialRange,
          title: title,
          startLabel: startLabel,
          endLabel: endLabel,
          durationWord: durationWord,
        ),
      );
    },
  );
}

class _DateRangeContent extends StatefulWidget {
  const _DateRangeContent({
    required this.firstDate,
    required this.lastDate,
    this.initialRange,
    required this.title,
    required this.startLabel,
    required this.endLabel,
    required this.durationWord,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTimeRange? initialRange;
  final String title;
  final String startLabel;
  final String endLabel;

  /// Singular form: 'night' → '1 night / 3 nights', 'day' → '1 day / 3 days'.
  final String durationWord;

  @override
  State<_DateRangeContent> createState() => _DateRangeContentState();
}

class _DateRangeContentState extends State<_DateRangeContent> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  late DateTime _displayedDay;
  _StayDateStep _activeStep = _StayDateStep.checkIn;

  @override
  void initState() {
    super.initState();
    final i = widget.initialRange;
    if (i != null) {
      final normalized = _normalizeRange(i.start, i.end);
      _rangeStart = normalized.start;
      _rangeEnd = normalized.end;
      _displayedDay = _clampDate(normalized.end);
      _activeStep = _StayDateStep.checkOut;
    } else {
      _displayedDay = widget.firstDate;
    }
  }

  DateTime _clampDate(DateTime date) {
    final d = _dateOnly(date);
    if (d.isBefore(widget.firstDate)) return widget.firstDate;
    if (d.isAfter(widget.lastDate)) return widget.lastDate;
    return d;
  }

  DateTimeRange _normalizeRange(DateTime start, DateTime end) {
    var s = _clampDate(start);
    var e = _clampDate(end);
    if (!e.isAfter(s)) e = _clampDate(s.add(const Duration(days: 1)));
    if (!e.isAfter(s)) s = _clampDate(e.subtract(const Duration(days: 1)));
    return DateTimeRange(start: s, end: e);
  }

  void _onDateChanged(DateTime selected) {
    final day = _clampDate(selected);
    setState(() {
      _displayedDay = day;

      if (_isSameDay(day, widget.lastDate)) {
        final start = _rangeStart;
        final normalized =
            _activeStep == _StayDateStep.checkOut &&
                    start != null &&
                    day.isAfter(start)
                ? _normalizeRange(start, day)
                : _normalizeRange(
                    widget.lastDate.subtract(const Duration(days: 1)),
                    widget.lastDate,
                  );
        _rangeStart = normalized.start;
        _rangeEnd = normalized.end;
        _activeStep = _StayDateStep.checkOut;
        return;
      }

      if (_activeStep == _StayDateStep.checkIn) {
        _rangeStart = day;
        if (_rangeEnd != null && !_rangeEnd!.isAfter(day)) _rangeEnd = null;
        _activeStep = _StayDateStep.checkOut;
        return;
      }

      final start = _rangeStart;
      if (start == null) {
        _rangeStart = day;
        _rangeEnd = null;
        _activeStep = _StayDateStep.checkOut;
        return;
      }

      if (day.isAfter(start)) {
        final normalized = _normalizeRange(start, day);
        _rangeStart = normalized.start;
        _rangeEnd = normalized.end;
      } else {
        _rangeStart = day;
        _rangeEnd = null;
      }
    });
  }

  DateTime get _pickerFirstDate {
    if (_activeStep == _StayDateStep.checkOut && _rangeStart != null) {
      return _clampDate(_rangeStart!.add(const Duration(days: 1)));
    }
    return widget.firstDate;
  }

  DateTime get _pickerInitialDate {
    if (_activeStep == _StayDateStep.checkOut) {
      final preferred =
          _rangeEnd ??
          _rangeStart?.add(const Duration(days: 1)) ??
          _displayedDay;
      return _clampDate(preferred);
    }
    return _clampDate(_rangeStart ?? _displayedDay);
  }

  void _onCancel() => Navigator.of(context).pop();

  void _onOk() {
    var s = _rangeStart;
    var e = _rangeEnd;
    if (s == null) return;
    e ??= s.add(const Duration(days: 1));
    Navigator.of(context).pop(_normalizeRange(s, e));
  }

  int? get _spanCount {
    final a = _rangeStart;
    final b = _rangeEnd;
    if (a == null || b == null) return null;
    final n = b.difference(a).inDays;
    return n > 0 ? n : null;
  }

  String _durationLabel(int n) {
    final word = widget.durationWord;
    return n == 1 ? '1 $word' : '$n ${word}s';
  }

  String _badgeUnit() => widget.durationWord == 'night' ? 'nt' : 'd';

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    final theme = Theme.of(context);
    final dpt = DatePickerTheme.of(context);
    final tok = context.vacanzaTokens;

    final hasStart = _rangeStart != null;
    final hasEnd = _rangeEnd != null;
    final span = _spanCount;

    final pickerFirstDate = _pickerFirstDate;
    var pickerInitialDate = _pickerInitialDate;
    if (pickerInitialDate.isBefore(pickerFirstDate)) {
      pickerInitialDate = pickerFirstDate;
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ─────────────────────────────────────────────
            Container(
              color: dpt.headerBackgroundColor ?? accent,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: (dpt.headerForegroundColor ?? cs.onPrimary)
                          .withValues(alpha: 0.92),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!hasStart)
                    Text(
                      'Tap your ${widget.startLabel.toLowerCase()} day, '
                      'then your ${widget.endLabel.toLowerCase()} day.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: (dpt.headerForegroundColor ?? cs.onPrimary)
                            .withValues(alpha: 0.95),
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else if (!hasEnd)
                    Text(
                      '${widget.startLabel}: ${loc.formatShortDate(_rangeStart!)}.\n'
                      'Now pick your ${widget.endLabel.toLowerCase()} day.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: (dpt.headerForegroundColor ?? cs.onPrimary)
                            .withValues(alpha: 0.95),
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${loc.formatShortDate(_rangeStart!)}  –  '
                          '${loc.formatShortDate(_rangeEnd!)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: dpt.headerForegroundColor ?? cs.onPrimary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (span != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _durationLabel(span),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: (dpt.headerForegroundColor ?? cs.onPrimary)
                                  .withValues(alpha: 0.88),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),

            // ── Step cards ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _StayDateCard(
                      label: widget.startLabel,
                      dateText: _rangeStart == null
                          ? 'Select'
                          : loc.formatShortDate(_rangeStart!),
                      isActive: _activeStep == _StayDateStep.checkIn,
                      accent: accent,
                      textColor: tok.textMain,
                      mutedColor: tok.textSub,
                      onTap: () => setState(() {
                        _activeStep = _StayDateStep.checkIn;
                        _displayedDay = _clampDate(_rangeStart ?? _displayedDay);
                      }),
                    ),
                  ),
                  _SpanBadge(span: span, accent: accent, unit: _badgeUnit()),
                  Expanded(
                    child: _StayDateCard(
                      label: widget.endLabel,
                      dateText: _rangeEnd == null
                          ? 'Select'
                          : loc.formatShortDate(_rangeEnd!),
                      isActive: _activeStep == _StayDateStep.checkOut,
                      accent: accent,
                      textColor: tok.textMain,
                      mutedColor: tok.textSub,
                      onTap: () => setState(() {
                        _activeStep = _StayDateStep.checkOut;
                        _displayedDay = _clampDate(
                          _rangeEnd ??
                              _rangeStart?.add(const Duration(days: 1)) ??
                              _displayedDay,
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            // ── Calendar ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
              child: Theme(
                data: theme.copyWith(
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(foregroundColor: accent),
                  ),
                ),
                child: CalendarDatePicker(
                  key: ValueKey(
                    '${_activeStep.name}-${pickerFirstDate.millisecondsSinceEpoch}'
                    '-${pickerInitialDate.millisecondsSinceEpoch}',
                  ),
                  initialDate: pickerInitialDate,
                  firstDate: pickerFirstDate,
                  lastDate: widget.lastDate,
                  currentDate: _dateOnly(DateTime.now()),
                  onDateChanged: _onDateChanged,
                  selectableDayPredicate: (day) {
                    final d = _dateOnly(day);
                    return !d.isBefore(pickerFirstDate) &&
                        !d.isAfter(widget.lastDate);
                  },
                ),
              ),
            ),

            // ── Actions ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 50),
                child: OverflowBar(
                  alignment: MainAxisAlignment.end,
                  overflowSpacing: 6,
                  children: [
                    TextButton(
                      onPressed: _onCancel,
                      child: Text(
                        loc.cancelButtonLabel,
                        style: TextStyle(
                          color: tok.textSub,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: hasStart ? _onOk : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        loc.okButtonLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpanBadge extends StatelessWidget {
  const _SpanBadge({
    required this.span,
    required this.accent,
    required this.unit,
  });

  final int? span;
  final Color accent;

  /// Compact unit abbreviation: 'nt' for nights, 'd' for days.
  final String unit;

  @override
  Widget build(BuildContext context) {
    if (span == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Icon(
          Icons.arrow_forward_rounded,
          size: 16,
          color: accent.withValues(alpha: 0.35),
        ),
      );
    }
    final label = span == 1 ? '1\n$unit' : '$span\n${unit}s';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.28), width: 1),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: accent,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _StayDateCard extends StatelessWidget {
  const _StayDateCard({
    required this.label,
    required this.dateText,
    required this.isActive,
    required this.accent,
    required this.textColor,
    required this.mutedColor,
    required this.onTap,
  });

  final String label;
  final String dateText;
  final bool isActive;
  final Color accent;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isActive
                ? accent.withValues(alpha: 0.12)
                : mutedColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? accent : mutedColor.withValues(alpha: 0.20),
              width: isActive ? 1.7 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isActive ? accent : mutedColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                dateText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
