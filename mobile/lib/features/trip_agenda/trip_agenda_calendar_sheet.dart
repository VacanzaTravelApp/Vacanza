import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/navigation/route_open_requests.dart';
import 'package:mobile/core/theme/vacanza_tokens.dart';
import 'package:mobile/core/widgets/vacanza_gradient_button.dart';
import 'package:mobile/features/ai/presentation/cubit/active_route_cubit.dart';
import 'package:mobile/features/trip_calendar/data/api/trip_calendar_api_client.dart';
import 'package:mobile/features/trip_calendar/services/ics_export_service.dart';

import 'trip_agenda_event.dart';

const _kMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _kWeekdayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Theme-aware colors for Trip Agenda (light / dark).
@immutable
class _TripPalette {
  const _TripPalette({
    required this.surface,
    required this.textMain,
    required this.textMuted,
    required this.navBtn,
    required this.navIcon,
    required this.cancelBg,
    required this.cancelFg,
    required this.hintBg,
    required this.hintFg,
    required this.gridBorder,
    required this.gridDivider,
    required this.todayCell,
    required this.selectedCell,
    required this.rangeAccent,
    required this.todayBadge,
    required this.dayNum,
    required this.scrim,
    required this.popupShadow,
    required this.inputFill,
    required this.inputBorder,
    required this.inputFocusedBorder,
    required this.rowBg,
    required this.addButtonBg,
    required this.addButtonDisabledBg,
    required this.addButtonDisabledFg,
  });

  final Color surface;
  final Color textMain;
  final Color textMuted;
  final Color navBtn;
  final Color navIcon;
  final Color cancelBg;
  final Color cancelFg;
  final Color hintBg;
  final Color hintFg;
  final Color gridBorder;
  final Color gridDivider;
  final Color todayCell;
  final Color selectedCell;
  final Color rangeAccent;
  final Color todayBadge;
  final Color dayNum;
  final Color scrim;
  final Color popupShadow;
  final Color inputFill;
  final Color inputBorder;
  final Color inputFocusedBorder;
  final Color rowBg;
  final Color addButtonBg;
  final Color addButtonDisabledBg;
  final Color addButtonDisabledFg;

  factory _TripPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = theme.extension<VacanzaTokens>() ?? VacanzaTokens.light;
    final isDark = theme.brightness == Brightness.dark;
    final vb = t.vividBlue;

    final inputFill = scheme.surfaceContainerHighest;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE2E8F0);

    return _TripPalette(
      surface: t.cardBg,
      textMain: t.textMain,
      textMuted: t.textSub,
      navBtn: t.actionBarInactiveBg,
      navIcon: t.actionBarIcon,
      cancelBg: const Color(0xFFFEE2E2),
      cancelFg: const Color(0xFFDC2626),
      hintBg: vb.withValues(alpha: isDark ? 0.18 : 0.12),
      hintFg: isDark ? vb : const Color(0xFF2563EB),
      gridBorder: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : const Color(0xFFF1F5F9),
      gridDivider: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : const Color(0xFFF8FAFC),
      // Bugün hücresi: gece modunda tema mavi (vividBlue); gündüzde hafif mavi tint.
      todayCell: isDark
          ? vb.withValues(alpha: 0.14)
          : vb.withValues(alpha: 0.10),
      // Seçili aralık: gündüzde okunaklı açık mavi zemin; gece yarı saydam mavi.
      selectedCell: isDark
          ? vb.withValues(alpha: 0.24)
          : const Color(0xFFDBEAFE),
      rangeAccent: vb,
      // Bugün sayı rozeti: gece tema mavisi; gündüz klasik vurgu (kırmızı).
      todayBadge: isDark ? vb : const Color(0xFFEF4444),
      dayNum: t.textSub,
      scrim: t.overlayScrim,
      popupShadow: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
      inputFill: inputFill,
      inputBorder: border,
      inputFocusedBorder: vb,
      rowBg: isDark
          ? scheme.surfaceContainerHigh.withValues(alpha: 0.6)
          : const Color(0xFFF8FAFC),
      addButtonBg: vb,
      addButtonDisabledBg: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : const Color(0xFFE2E8F0),
      addButtonDisabledFg: t.textSub,
    );
  }
}

class _Cell {
  const _Cell({required this.day, required this.isCurrentMonth});
  final int day;
  final bool isCurrentMonth;
}

List<_Cell> _buildCells(int year, int month) {
  final dim = DateTime(year, month + 1, 0).day;
  final first = DateTime(year, month, 1);
  final fd = first.weekday - 1;
  final prevMonth = month == 1 ? 12 : month - 1;
  final prevYear = month == 1 ? year - 1 : year;
  final prevDim = DateTime(prevYear, prevMonth + 1, 0).day;

  final cells = <_Cell>[];
  for (var i = fd - 1; i >= 0; i--) {
    cells.add(_Cell(day: prevDim - i, isCurrentMonth: false));
  }
  for (var d = 1; d <= dim; d++) {
    cells.add(_Cell(day: d, isCurrentMonth: true));
  }
  while (cells.length < 42) {
    final n = cells.length - fd - dim + 1;
    cells.add(_Cell(day: n, isCurrentMonth: false));
  }
  return cells;
}

/// Trip Agenda — same behavior as web CalendarModal.
class TripAgendaCalendarSheet extends StatefulWidget {
  final void Function(String routeId)? onOpenRouteFromCalendar;

  const TripAgendaCalendarSheet({
    super.key,
    this.onOpenRouteFromCalendar,
  });

  @override
  State<TripAgendaCalendarSheet> createState() =>
      _TripAgendaCalendarSheetState();
}

class _TripAgendaCalendarSheetState extends State<TripAgendaCalendarSheet>
    with SingleTickerProviderStateMixin {
  late int _year;
  late int _month;

  final List<TripAgendaEvent> _events = [];
  List<TripCalendarEventRow> _remoteEvents = const [];
  bool _remoteLoading = false;

  int? _selectStart;
  int? _selectEnd;
  bool _showForm = false;
  final _titleController = TextEditingController();
  String _newCategory = 'Activity';
  bool _calendarExporting = false;

  /// Form overlay: fade + scale (smooth giriş/çıkış).
  late AnimationController _sheetAnim;
  late Animation<double> _sheetFade;
  late Animation<double> _sheetScale;

  static const double _gridRowHeight = 76;
  static const int _gridRows = 6;
  static const double _gridHeight = _gridRows * _gridRowHeight;

  Future<void> _openLocalDetail(TripAgendaEvent ev) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final p = _TripPalette.of(ctx);
        return _detailSheet(
          ctx,
          palette: p,
          title: ev.title,
          subtitle:
              ev.endDay != null ? '${ev.day}–${ev.endDay} ${_kMonthNames[_month - 1]} $_year' : '${ev.day} ${_kMonthNames[_month - 1]} $_year',
          actions: [
            _DetailAction.danger(
              label: 'Remove note',
              onTap: () {
                final idx = _events.indexOf(ev);
                if (idx >= 0) _removeEventAt(idx);
                Navigator.pop(ctx);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _openRemoteDetail(TripCalendarEventRow ev) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final p = _TripPalette.of(ctx);
        final dateStr =
            '${_kMonthNames[_month - 1]} ${ev.eventDate.day}, $_year';
        final multi = ev.totalDays > 1;
        final label =
            multi ? 'Day ${ev.itineraryDay} of ${ev.totalDays}' : null;
        final computedStart = ev.eventDate.subtract(
          Duration(days: (ev.itineraryDay - 1).clamp(0, 3650)),
        );
        return _detailSheet(
          ctx,
          palette: p,
          title: ev.title,
          subtitle: [dateStr, label].whereType<String>().join(' • '),
          actions: [
            _DetailAction.primary(
              label: 'Open on map',
              onTap: () async {
                Navigator.pop(ctx);
                RouteOpenRequests.requestOpen(
                  ev.routeId,
                  day: ev.itineraryDay,
                );
                // Close overlays and return to the map screen.
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
            ),
            _DetailAction.muted(
              label: 'Add to phone calendar',
              onTap: () async {
                Navigator.pop(ctx);
                if (_calendarExporting) return;
                setState(() => _calendarExporting = true);
                try {
                  final today = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        computedStart.isBefore(today) ? today : computedStart,
                    firstDate: DateTime(today.year - 1),
                    lastDate: DateTime(today.year + 5),
                    helpText: 'Select first trip day',
                  );
                  if (!context.mounted) return;
                  if (picked == null) return;
                  await context.read<IcsExportService>().registerAndOpenRouteIcs(
                    routeId: ev.routeId,
                    eventDate: picked,
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  if (IcsExportService.isConflict409(e)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('This route is already on that day.'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not export calendar file.'),
                      ),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _calendarExporting = false);
                }
              },
            ),
            _DetailAction.danger(
              label: 'Remove this day',
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await context
                      .read<TripCalendarApiClient>()
                      .deleteTripCalendarEvent(ev.eventId);
                  await _loadRemoteEvents();
                } catch (_) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not remove calendar item.'),
                    ),
                  );
                }
              },
            ),
            if (multi)
              _DetailAction.muted(
                label: 'Remove all ${ev.totalDays} days',
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await context
                        .read<TripCalendarApiClient>()
                        .deleteTripCalendarEventsByRoute(ev.routeId);
                    await _loadRemoteEvents();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Trip removed from calendar.')),
                    );
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not remove trip from calendar.'),
                      ),
                    );
                  }
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _loadRemoteEvents() async {
    setState(() => _remoteLoading = true);
    try {
      final api = context.read<TripCalendarApiClient>();
      final rows = await api.listTripCalendarEvents(year: _year, month: _month);
      if (!mounted) return;
      setState(() => _remoteEvents = rows);
    } catch (_) {
      if (!mounted) return;
      setState(() => _remoteEvents = const []);
    } finally {
      if (mounted) setState(() => _remoteLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _year = n.year;
    _month = n.month;
    _sheetAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _sheetFade = CurvedAnimation(
      parent: _sheetAnim,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _sheetScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _sheetAnim, curve: Curves.easeOutCubic),
    );

    // Web parity: load server-side trip-calendar events for this month.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadRemoteEvents());
    });
  }

  @override
  void dispose() {
    _sheetAnim.dispose();
    _titleController.dispose();
    super.dispose();
  }

  int? _rangeMin() {
    if (_selectStart == null) return null;
    if (_selectEnd == null) return _selectStart;
    return _selectStart! < _selectEnd! ? _selectStart : _selectEnd;
  }

  int? _rangeMax() {
    if (_selectStart == null) return null;
    if (_selectEnd == null) return _selectStart;
    return _selectStart! > _selectEnd! ? _selectStart : _selectEnd;
  }

  bool _isInRange(int d, bool cur) {
    if (!cur) return false;
    final rmin = _rangeMin();
    final rmax = _rangeMax();
    if (rmin != null && rmax != null) {
      return d >= rmin && d <= rmax;
    }
    return false;
  }

  List<TripAgendaEvent> _eventsForDay(int d) {
    return _events.where((e) => e.coversDay(d, _month, _year)).toList();
  }

  List<TripCalendarEventRow> _remoteEventsForDay(int d) {
    return _remoteEvents.where((re) {
      final dt = re.eventDate;
      return dt.year == _year && dt.month == _month && dt.day == d;
    }).toList();
  }

  void _resetSelection() {
    if (_showForm) {
      unawaited(_dismissFormOverlay());
    } else {
      setState(() {
        _selectStart = null;
        _selectEnd = null;
        _titleController.clear();
      });
    }
  }

  Future<void> _dismissFormOverlay() async {
    FocusScope.of(context).unfocus();
    await _sheetAnim.reverse();
    if (!mounted) return;
    setState(() {
      _selectStart = null;
      _selectEnd = null;
      _showForm = false;
      _titleController.clear();
    });
  }

  void _onCellTap(int day, bool cur) {
    if (!cur) return;
    if (_isPastDay(day, cur)) return;
    if (_selectStart == null) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectStart = day;
        _selectEnd = null;
        _showForm = false;
      });
      _sheetAnim.reset();
    } else if (_selectEnd == null) {
      HapticFeedback.lightImpact();
      setState(() {
        _selectEnd = day;
        _showForm = true;
        _titleController.clear();
        _newCategory = 'Activity';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _showForm) {
          _sheetAnim.forward(from: 0);
        }
      });
    }
  }

  Future<void> _addEvent() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _selectStart == null) return;
    final s = _rangeMin()!;
    final en = _rangeMax()!;
    FocusScope.of(context).unfocus();
    await _sheetAnim.reverse();
    if (!mounted) return;
    setState(() {
      _events.add(
        TripAgendaEvent(
          title: title,
          category: _newCategory,
          day: s,
          endDay: en != s ? en : null,
          month: _month,
          year: _year,
        ),
      );
      _selectStart = null;
      _selectEnd = null;
      _showForm = false;
      _titleController.clear();
    });
  }

  void _removeEventAt(int index) {
    setState(() {
      _events.removeAt(index);
    });
  }

  Future<void> _goToday() async {
    if (_showForm) await _dismissFormOverlay();
    if (!mounted) return;
    final n = DateTime.now();
    setState(() {
      _year = n.year;
      _month = n.month;
    });
    unawaited(_loadRemoteEvents());
  }

  Future<void> _prevMonth() async {
    if (_showForm) await _dismissFormOverlay();
    if (!mounted) return;
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
    });
    unawaited(_loadRemoteEvents());
  }

  Future<void> _nextMonth() async {
    if (_showForm) await _dismissFormOverlay();
    if (!mounted) return;
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
    });
    unawaited(_loadRemoteEvents());
  }

  bool _isToday(int d, bool cur) {
    if (!cur) return false;
    final n = DateTime.now();
    return d == n.day && _month == n.month && _year == n.year;
  }

  DateTime _cellDate(int day) => DateTime(_year, _month, day);

  /// Bugünün tarihinden önceki günler (aynı ay içinde seçim için kapalı).
  bool _isPastDay(int day, bool cur) {
    if (!cur) return false;
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return _cellDate(day).isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    final p = _TripPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final cells = _buildCells(_year, _month);
    final rmin = _rangeMin();
    final rmax = _rangeMax();
    final dynamic activeRouteState = () {
      try {
        return context.read<ActiveRouteCubit>().state;
      } catch (_) {
        return null;
      }
    }();
    final String? routeId = activeRouteState?.routeId as String?;
    final route = activeRouteState?.route;
    final tripStart =
        IcsExportService.tryParseIsoDate(route?.tripStartDate);

    Future<DateTime?> pickDate({required DateTime initial}) async {
      final today = DateTime.now();
      final d = await showDatePicker(
        context: context,
        initialDate: initial.isBefore(today) ? today : initial,
        firstDate: DateTime(today.year - 1),
        lastDate: DateTime(today.year + 5),
        helpText: 'Select first trip day',
      );
      return d;
    }

    Future<void> exportActiveRoute() async {
      if (routeId == null) return;
      if (_calendarExporting) return;
      setState(() => _calendarExporting = true);
      try {
        final initial = tripStart ?? DateTime.now();
        final chosen = await pickDate(initial: initial);
        if (chosen == null) return;
        await context.read<IcsExportService>().registerAndOpenRouteIcs(
          routeId: routeId,
          eventDate: chosen,
        );
      } catch (e) {
        if (!context.mounted) return;
        if (IcsExportService.isConflict409(e)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This route is already on that day.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not export calendar file.')),
          );
        }
      } finally {
        if (mounted) setState(() => _calendarExporting = false);
      }
    }

    return Material(
      color: p.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.textMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w300,
                            color: p.textMain,
                            height: 1.1,
                          ),
                          children: [
                            TextSpan(text: _kMonthNames[_month - 1]),
                            TextSpan(
                              text: ' $_year',
                              style: TextStyle(
                                color: p.textMain.withValues(alpha: 0.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_selectStart != null)
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: p.cancelBg,
                          foregroundColor: p.cancelFg,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _resetSelection,
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    if (_selectStart != null) const SizedBox(width: 6),
                    if (_remoteLoading) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 6),
                    ],
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: p.navBtn,
                        foregroundColor: p.navIcon,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed:
                          routeId == null || _calendarExporting
                              ? null
                              : () => unawaited(exportActiveRoute()),
                      child:
                          _calendarExporting
                              ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                              : Text(
                                'Export',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: routeId == null
                                      ? p.textMuted.withValues(alpha: 0.5)
                                      : p.navIcon,
                                ),
                              ),
                    ),
                    const SizedBox(width: 6),
                    _navIconBtn(
                      p: p,
                      icon: Icons.chevron_left_rounded,
                      onPressed: () => unawaited(_prevMonth()),
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: p.navBtn,
                        foregroundColor: p.navIcon,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => unawaited(_goToday()),
                      child: Text(
                        'Today',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: p.navIcon,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _navIconBtn(
                      p: p,
                      icon: Icons.chevron_right_rounded,
                      onPressed: () => unawaited(_nextMonth()),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _selectStart != null && _selectEnd == null
                      ? Column(
                          key: const ValueKey('rangeHint'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: p.hintBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Select end date (started from $_selectStart ${_kMonthNames[_month - 1]})',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: p.hintFg,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: 12),
                Row(
                  children: _kWeekdayHeaders
                      .map(
                        (d) => Expanded(
                          child: Text(
                            d,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: p.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: _gridHeight,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisExtent: _gridRowHeight,
                    ),
                    itemCount: 42,
                    itemBuilder: (context, idx) {
                      final c = cells[idx];
                      final evts = c.isCurrentMonth
                          ? _eventsForDay(c.day)
                          : <TripAgendaEvent>[];
                      final inRange = c.isCurrentMonth &&
                          _isInRange(c.day, c.isCurrentMonth);
                      final isRStart = c.isCurrentMonth &&
                          rmin != null &&
                          c.day == rmin;
                      final isREnd = c.isCurrentMonth &&
                          rmax != null &&
                          c.day == rmax;
                      final today = _isToday(c.day, c.isCurrentMonth);
                      final past = _isPastDay(c.day, c.isCurrentMonth);
                      final showRangeEndBorder = isREnd;

                      return GestureDetector(
                        onTap:
                            past
                                ? null
                                : () => _onCellTap(c.day, c.isCurrentMonth),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            color: past
                                ? p.textMuted.withValues(alpha: 0.06)
                                : (inRange
                                    ? p.selectedCell
                                    : (today && c.isCurrentMonth
                                        ? p.todayCell
                                        : null)),
                            border: Border(
                              top: BorderSide(color: p.gridBorder),
                              right: showRangeEndBorder
                                  ? BorderSide(
                                      color: p.rangeAccent,
                                      width: 3,
                                    )
                                  : (idx % 7 == 6
                                      ? BorderSide.none
                                      : BorderSide(color: p.gridDivider)),
                              bottom: BorderSide(color: p.gridBorder),
                              left: isRStart
                                  ? BorderSide(
                                      color: p.rangeAccent,
                                      width: 3,
                                    )
                                  : BorderSide.none,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: today && c.isCurrentMonth
                                            ? p.todayBadge
                                            : null,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${c.day}',
                                        style: TextStyle(
                                          fontSize: today && c.isCurrentMonth
                                              ? 11
                                              : 12,
                                          fontWeight: today && c.isCurrentMonth
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: c.isCurrentMonth
                                              ? (past
                                                  ? p.textMuted.withValues(
                                                      alpha: 0.45,
                                                    )
                                                  : (today
                                                      ? Colors.white
                                                      : p.dayNum))
                                              : p.textMuted.withValues(
                                                  alpha: 0.35,
                                                ),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (c.isCurrentMonth &&
                                        _selectStart == null &&
                                        !past)
                                      Icon(
                                        Icons.add_rounded,
                                        size: 11,
                                        color: p.textMuted.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Expanded(
                                  child: c.isCurrentMonth
                                      ? _EventChips(
                                          events: evts,
                                          remoteEvents: _remoteEventsForDay(
                                            c.day,
                                          ),
                                          muted: p.textMuted,
                                          onTapRemote: (re) =>
                                              unawaited(_openRemoteDetail(re)),
                                          onTapLocal: (le) =>
                                              unawaited(_openLocalDetail(le)),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_showForm && rmin != null && rmax != null)
              Positioned.fill(
                child: FadeTransition(
                  opacity: _sheetFade,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => unawaited(_dismissFormOverlay()),
                        child: ColoredBox(color: p.scrim),
                      ),
                      Center(
                        child: ScaleTransition(
                          scale: _sheetScale,
                          alignment: Alignment.center,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 12,
                              right: 12,
                              bottom: bottomInset,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: Material(
                                color: p.surface,
                                elevation: 12,
                                shadowColor: p.popupShadow,
                                borderRadius: BorderRadius.circular(16),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                    canvasColor: p.surface,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {},
                                    behavior: HitTestBehavior.deferToChild,
                                    child: _AddEventPanel(
                                      palette: p,
                                      colorScheme: scheme,
                                      monthName: _kMonthNames[_month - 1],
                                      rangeMin: rmin,
                                      rangeMax: rmax,
                                      events: _events,
                                      month: _month,
                                      year: _year,
                                      titleController: _titleController,
                                      newCategory: _newCategory,
                                      onCategoryChanged: (v) =>
                                          setState(() => _newCategory = v),
                                      onAdd: () => unawaited(_addEvent()),
                                      onCloseForm: _resetSelection,
                                      onRemoveAt: _removeEventAt,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
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

  Widget _navIconBtn({
    required _TripPalette p,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Material(
        color: p.navBtn,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Icon(icon, size: 16, color: p.navIcon),
        ),
      ),
    );
  }
}

class _EventChips extends StatelessWidget {
  const _EventChips({
    required this.events,
    required this.remoteEvents,
    required this.muted,
    this.onTapLocal,
    this.onTapRemote,
  });

  final List<TripAgendaEvent> events;
  final List<TripCalendarEventRow> remoteEvents;
  final Color muted;
  final void Function(TripAgendaEvent ev)? onTapLocal;
  final void Function(TripCalendarEventRow ev)? onTapRemote;

  @override
  Widget build(BuildContext context) {
    final local = events;
    final remote = remoteEvents;
    final combinedCount = remote.length + local.length;

    List<Widget> chips = [];
    for (final re in remote.take(2)) {
      chips.add(
        GestureDetector(
          onTap: onTapRemote == null ? null : () => onTapRemote!(re),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6), // web ROUTE_EVENT_COLOR
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _formatRemoteLabel(re),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.35,
              ),
            ),
          ),
        ),
      );
      if (chips.length >= 2) break;
    }
    if (chips.length < 2) {
      for (final le in local.take(2 - chips.length)) {
        chips.add(
          GestureDetector(
            onTap: onTapLocal == null ? null : () => onTapLocal!(le),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: le.color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                le.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final chip in chips)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: chip,
          ),
        if (combinedCount > 2)
          Text(
            '+${combinedCount - 2}',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: muted.withValues(alpha: 0.95),
            ),
          ),
      ],
    );
  }

  static String _formatRemoteLabel(TripCalendarEventRow re) {
    final td = re.totalDays <= 0 ? 1 : re.totalDays;
    final id = re.itineraryDay <= 0 ? 1 : re.itineraryDay;
    if (td > 1) return 'Day $id/$td · ${re.title}';
    return re.title;
  }
}

class _AddEventPanel extends StatefulWidget {
  const _AddEventPanel({
    required this.palette,
    required this.colorScheme,
    required this.monthName,
    required this.rangeMin,
    required this.rangeMax,
    required this.events,
    required this.month,
    required this.year,
    required this.titleController,
    required this.newCategory,
    required this.onCategoryChanged,
    required this.onAdd,
    required this.onCloseForm,
    required this.onRemoveAt,
  });

  final _TripPalette palette;
  final ColorScheme colorScheme;
  final String monthName;
  final int rangeMin;
  final int rangeMax;
  final List<TripAgendaEvent> events;
  final int month;
  final int year;
  final TextEditingController titleController;
  final String newCategory;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onAdd;
  final VoidCallback onCloseForm;
  final void Function(int index) onRemoveAt;

  @override
  State<_AddEventPanel> createState() => _AddEventPanelState();
}

class _AddEventPanelState extends State<_AddEventPanel> {
  @override
  void initState() {
    super.initState();
    widget.titleController.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    widget.titleController.removeListener(_onTitleChanged);
    super.dispose();
  }

  void _onTitleChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final scheme = widget.colorScheme;
    final onSurface = scheme.onSurface;

    final header = widget.rangeMin != widget.rangeMax
        ? '${widget.rangeMin} – ${widget.rangeMax} ${widget.monthName}'
        : '${widget.rangeMin} ${widget.monthName}';

    final canAdd = widget.titleController.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.deferToChild,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    header,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: p.textMain,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: p.textMuted,
                    size: 20,
                  ),
                  onPressed: widget.onCloseForm,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            Divider(height: 20, color: p.gridBorder),
            for (final e in widget.events.asMap().entries)
              if (e.value.day == widget.rangeMin &&
                  e.value.month == widget.month &&
                  e.value.year == widget.year)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: p.rowBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: e.value.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(
                                fontSize: 12,
                                color: p.textMain,
                              ),
                              children: [
                                TextSpan(text: e.value.title),
                                if (e.value.endDay != null)
                                  TextSpan(
                                    text:
                                        ' (${e.value.day}–${e.value.endDay})',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: p.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => widget.onRemoveAt(e.key),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: p.textMuted.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.titleController,
              style: TextStyle(
                fontSize: 13,
                color: onSurface,
              ),
              cursorColor: scheme.primary,
              decoration: InputDecoration(
                hintText: 'Event name...',
                filled: true,
                fillColor: p.inputFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: p.inputBorder,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: p.inputFocusedBorder,
                    width: 1.5,
                  ),
                ),
                hintStyle: TextStyle(
                  color: p.textMuted.withValues(alpha: 0.85),
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (canAdd) widget.onAdd();
              },
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: p.surface,
                    ),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        filled: true,
                        fillColor: p.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: p.inputBorder,
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: p.inputBorder,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: widget.newCategory,
                          isExpanded: true,
                          dropdownColor: p.surface,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: p.textMuted,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: onSurface,
                          ),
                          items: TripAgendaCategories.keys
                              .map(
                                (k) => DropdownMenuItem(
                                  value: k,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color:
                                              TripAgendaCategories.colorForKey(
                                                  k),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        k,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) widget.onCategoryChanged(v);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: p.addButtonBg,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: p.addButtonDisabledBg,
                    disabledForegroundColor: p.addButtonDisabledFg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: canAdd ? widget.onAdd : null,
                  child: const Text(
                    'Add',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens Trip Agenda bottom sheet (web CalendarModal equivalent).
Future<void> showTripAgendaCalendar(
  BuildContext context, {
  void Function(String routeId)? onOpenRouteFromCalendar,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.94,
        minChildSize: 0.55,
        maxChildSize: 0.94,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: TripAgendaCalendarSheet(
              onOpenRouteFromCalendar: onOpenRouteFromCalendar,
            ),
          );
        },
      );
    },
  );
}

class _DetailAction {
  final String label;
  final VoidCallback onTap;
  final _DetailActionStyle style;

  const _DetailAction({
    required this.label,
    required this.onTap,
    required this.style,
  });

  factory _DetailAction.primary({
    required String label,
    required VoidCallback onTap,
  }) => _DetailAction(label: label, onTap: onTap, style: _DetailActionStyle.primary);

  factory _DetailAction.muted({
    required String label,
    required VoidCallback onTap,
  }) => _DetailAction(label: label, onTap: onTap, style: _DetailActionStyle.muted);

  factory _DetailAction.danger({
    required String label,
    required VoidCallback onTap,
  }) => _DetailAction(label: label, onTap: onTap, style: _DetailActionStyle.danger);
}

enum _DetailActionStyle { primary, muted, danger }

Widget _detailSheet(
  BuildContext context, {
  required _TripPalette palette,
  required String title,
  required String subtitle,
  required List<_DetailAction> actions,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    child: Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: palette.textMuted.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: palette.textMain,
              ),
            ),
            const SizedBox(height: 12),
            for (final a in actions) ...[
              _detailActionButton(context, palette: palette, action: a),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget _detailActionButton(
  BuildContext context, {
  required _TripPalette palette,
  required _DetailAction action,
}) {
  final theme = Theme.of(context);
  final tokens = theme.extension<VacanzaTokens>() ?? VacanzaTokens.light;
  final cs = theme.colorScheme;

  switch (action.style) {
    case _DetailActionStyle.primary:
      return VacanzaGradientButton(
        label: action.label,
        onPressed: action.onTap,
        minHeight: 46,
        borderRadius: 16,
        horizontalPadding: 16,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      );
    case _DetailActionStyle.muted:
      return SizedBox(
        height: 46,
        child: OutlinedButton(
          onPressed: action.onTap,
          style: OutlinedButton.styleFrom(
            backgroundColor: tokens.actionBarInactiveBg.withValues(alpha: 0.88),
            foregroundColor: tokens.textMain,
            side: BorderSide(
              color: tokens.cardBorder.withValues(alpha: 0.55),
              width: 1.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            action.label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),
      );
    case _DetailActionStyle.danger:
      return SizedBox(
        height: 46,
        child: OutlinedButton(
          onPressed: action.onTap,
          style: OutlinedButton.styleFrom(
            backgroundColor: cs.errorContainer.withValues(alpha: 0.65),
            foregroundColor: cs.error,
            side: BorderSide(
              color: cs.error.withValues(alpha: 0.55),
              width: 1.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            action.label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),
      );
  }
}
