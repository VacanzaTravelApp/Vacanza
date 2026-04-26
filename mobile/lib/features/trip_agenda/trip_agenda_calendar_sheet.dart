import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/navigation/route_open_requests.dart';
import 'package:mobile/core/theme/vacanza_tokens.dart';
import 'package:mobile/features/ai/presentation/cubit/active_route_cubit.dart';
import 'package:mobile/features/trip_calendar/data/api/trip_calendar_api_client.dart';
import 'package:mobile/features/trip_calendar/services/ics_export_service.dart';

import 'trip_agenda_event.dart';

const _kMonthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const _kWeekdayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

// Stable per-trip color palette — same order as web.
const _kTripColors = [
  Color(0xFF8B5CF6),
  Color(0xFF3B82F6),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
  Color(0xFF06B6D4),
  Color(0xFFEF4444),
  Color(0xFF84CC16),
];

Color _tripColor(String routeId) {
  final hash = routeId.codeUnits.fold(0, (acc, c) => acc ^ c);
  return _kTripColors[hash.abs() % _kTripColors.length];
}

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
      todayCell: isDark ? vb.withValues(alpha: 0.14) : vb.withValues(alpha: 0.10),
      selectedCell: isDark ? vb.withValues(alpha: 0.24) : const Color(0xFFDBEAFE),
      rangeAccent: vb,
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
      builder: (ctx) => _detailSheet(
        ctx,
        palette: _TripPalette.of(ctx),
        color: ev.color,
        title: ev.title,
        subtitle: ev.endDay != null
            ? '${ev.day}–${ev.endDay} ${_kMonthNames[_month - 1]} $_year'
            : '${ev.day} ${_kMonthNames[_month - 1]} $_year',
        destination: null,
        dayBadge: null,
        actions: [
          _DetailAction.danger(
            icon: Icons.delete_outline_rounded,
            label: 'Remove note',
            onTap: () {
              final idx = _events.indexOf(ev);
              if (idx >= 0) _removeEventAt(idx);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openRemoteDetail(TripCalendarEventRow ev) async {
    final color = _tripColor(ev.routeId);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final p = _TripPalette.of(ctx);
        final dateStr =
            '${_kMonthNames[_month - 1]} ${ev.eventDate.day}, $_year';
        final multi = ev.totalDays > 1;
        final dayBadge =
            multi ? 'Day ${ev.itineraryDay} of ${ev.totalDays}' : null;
        final computedStart = ev.eventDate.subtract(
          Duration(days: (ev.itineraryDay - 1).clamp(0, 3650)),
        );

        return _detailSheet(
          ctx,
          palette: p,
          color: color,
          title: ev.title,
          subtitle: dateStr,
          destination: ev.destination,
          dayBadge: dayBadge,
          actions: [
            _DetailAction.primary(
              icon: Icons.map_rounded,
              label: 'Open on map',
              onTap: () async {
                Navigator.pop(ctx);
                RouteOpenRequests.requestOpen(ev.routeId, day: ev.itineraryDay);
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
            ),
            _DetailAction.muted(
              icon: Icons.calendar_today_rounded,
              label: 'Add to phone calendar',
              onTap: () async {
                Navigator.pop(ctx);
                if (_calendarExporting) return;
                setState(() => _calendarExporting = true);
                try {
                  final today = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: computedStart.isBefore(today)
                        ? today
                        : computedStart,
                    firstDate: DateTime(today.year - 1),
                    lastDate: DateTime(today.year + 5),
                    helpText: 'Select first trip day',
                  );
                  if (!context.mounted) return;
                  if (picked == null) return;
                  await context
                      .read<IcsExportService>()
                      .registerAndOpenRouteIcs(
                        routeId: ev.routeId,
                        eventDate: picked,
                      );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(IcsExportService.isConflict409(e)
                          ? 'This route is already on that day.'
                          : 'Could not export calendar file.'),
                    ),
                  );
                } finally {
                  if (mounted) setState(() => _calendarExporting = false);
                }
              },
            ),
            _DetailAction.danger(
              icon: Icons.remove_circle_outline_rounded,
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
                        content: Text('Could not remove calendar item.')),
                  );
                }
              },
            ),
            if (multi)
              _DetailAction.danger(
                icon: Icons.delete_sweep_rounded,
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
                      const SnackBar(
                          content: Text('Trip removed from calendar.')),
                    );
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Could not remove trip from calendar.')),
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
      final rows =
          await api.listTripCalendarEvents(year: _year, month: _month);
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
    if (rmin != null && rmax != null) return d >= rmin && d <= rmax;
    return false;
  }

  List<TripAgendaEvent> _eventsForDay(int d) =>
      _events.where((e) => e.coversDay(d, _month, _year)).toList();

  List<TripCalendarEventRow> _remoteEventsForDay(int d) =>
      _remoteEvents.where((re) {
        final dt = re.eventDate;
        return dt.year == _year && dt.month == _month && dt.day == d;
      }).toList();

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
        if (mounted && _showForm) _sheetAnim.forward(from: 0);
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
      _events.add(TripAgendaEvent(
        title: title,
        category: _newCategory,
        day: s,
        endDay: en != s ? en : null,
        month: _month,
        year: _year,
      ));
      _selectStart = null;
      _selectEnd = null;
      _showForm = false;
      _titleController.clear();
    });
  }

  void _removeEventAt(int index) => setState(() => _events.removeAt(index));

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
    final tripStart = IcsExportService.tryParseIsoDate(route?.tripStartDate);

    Future<DateTime?> pickDate({required DateTime initial}) async {
      final today = DateTime.now();
      return showDatePicker(
        context: context,
        initialDate: initial.isBefore(today) ? today : initial,
        firstDate: DateTime(today.year - 1),
        lastDate: DateTime(today.year + 5),
        helpText: 'Select first trip day',
      );
    }

    Future<void> exportActiveRoute() async {
      if (routeId == null || _calendarExporting) return;
      setState(() => _calendarExporting = true);
      try {
        final initial = tripStart ?? DateTime.now();
        final chosen = await pickDate(initial: initial);
        if (!context.mounted) return;
        if (chosen == null) return;
        await context.read<IcsExportService>().registerAndOpenRouteIcs(
              routeId: routeId,
              eventDate: chosen,
            );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(IcsExportService.isConflict409(e)
                ? 'This route is already on that day.'
                : 'Could not export calendar file.'),
          ),
        );
      } finally {
        if (mounted) setState(() => _calendarExporting = false);
      }
    }

    final exportEnabled = routeId != null && !_calendarExporting;

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
                // ── Drag handle ──
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
                const SizedBox(height: 14),
                // ── Header row ──
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                            color: p.textMain,
                            height: 1.1,
                          ),
                          children: [
                            TextSpan(text: _kMonthNames[_month - 1]),
                            TextSpan(
                              text: ' $_year',
                              style: TextStyle(
                                  color: p.textMain.withValues(alpha: 0.35)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_selectStart != null) ...[
                      _headerChip(
                        label: 'Cancel',
                        icon: Icons.close_rounded,
                        bg: p.cancelBg,
                        fg: p.cancelFg,
                        onTap: _resetSelection,
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (_remoteLoading) ...[
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: p.rangeAccent),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Export button
                    _headerChip(
                      label: _calendarExporting ? '' : 'Export',
                      icon: Icons.ios_share_rounded,
                      bg: exportEnabled
                          ? p.rangeAccent.withValues(alpha: isDark ? 0.22 : 0.12)
                          : p.navBtn,
                      fg: exportEnabled ? p.rangeAccent : p.textMuted.withValues(alpha: 0.45),
                      onTap: _calendarExporting
                          ? null
                          : () {
                              if (routeId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Open a trip on the map first to export it.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              unawaited(exportActiveRoute());
                            },
                      loading: _calendarExporting,
                    ),
                    const SizedBox(width: 6),
                    _navIconBtn(p: p, icon: Icons.chevron_left_rounded,
                        onPressed: () => unawaited(_prevMonth())),
                    const SizedBox(width: 4),
                    _headerChip(
                      label: 'Today',
                      icon: Icons.today_rounded,
                      bg: p.navBtn,
                      fg: p.navIcon,
                      onTap: () => unawaited(_goToday()),
                    ),
                    const SizedBox(width: 4),
                    _navIconBtn(p: p, icon: Icons.chevron_right_rounded,
                        onPressed: () => unawaited(_nextMonth())),
                  ],
                ),
                // ── Range hint ──
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _selectStart != null && _selectEnd == null
                      ? Column(
                          key: const ValueKey('rangeHint'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
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
                const SizedBox(height: 10),
                // ── Weekday headers ──
                Row(
                  children: _kWeekdayHeaders
                      .map((d) => Expanded(
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
                          ))
                      .toList(),
                ),
                const SizedBox(height: 2),
                // ── Calendar grid ──
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
                      final inRange =
                          c.isCurrentMonth && _isInRange(c.day, c.isCurrentMonth);
                      final isRStart =
                          c.isCurrentMonth && rmin != null && c.day == rmin;
                      final isREnd =
                          c.isCurrentMonth && rmax != null && c.day == rmax;
                      final today = _isToday(c.day, c.isCurrentMonth);
                      final past = _isPastDay(c.day, c.isCurrentMonth);

                      return GestureDetector(
                        onTap: past
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
                              right: isREnd
                                  ? BorderSide(
                                      color: p.rangeAccent, width: 3)
                                  : (idx % 7 == 6
                                      ? BorderSide.none
                                      : BorderSide(color: p.gridDivider)),
                              bottom: BorderSide(color: p.gridBorder),
                              left: isRStart
                                  ? BorderSide(
                                      color: p.rangeAccent, width: 3)
                                  : BorderSide.none,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
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
                                          fontSize:
                                              today && c.isCurrentMonth ? 11 : 12,
                                          fontWeight: today && c.isCurrentMonth
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: c.isCurrentMonth
                                              ? (past
                                                  ? p.textMuted.withValues(alpha: 0.45)
                                                  : (today
                                                      ? Colors.white
                                                      : p.dayNum))
                                              : p.textMuted.withValues(alpha: 0.35),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (c.isCurrentMonth &&
                                        _selectStart == null &&
                                        !past)
                                      Icon(Icons.add_rounded,
                                          size: 11,
                                          color: p.textMuted
                                              .withValues(alpha: 0.5)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Expanded(
                                  child: c.isCurrentMonth
                                      ? _EventChips(
                                          events: evts,
                                          remoteEvents:
                                              _remoteEventsForDay(c.day),
                                          muted: p.textMuted,
                                          onTapRemote: (re) => unawaited(
                                              _openRemoteDetail(re)),
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
            // ── Add event form overlay ──
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
                                left: 12, right: 12, bottom: bottomInset),
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 400),
                              child: Material(
                                color: p.surface,
                                elevation: 12,
                                shadowColor: p.popupShadow,
                                borderRadius: BorderRadius.circular(16),
                                child: Theme(
                                  data: Theme.of(context)
                                      .copyWith(canvasColor: p.surface),
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

  Widget _headerChip({
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback? onTap,
    bool loading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: loading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13, color: fg),
                  if (label.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ],
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
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: p.navBtn,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: p.navIcon),
      ),
    );
  }
}

// ── Event chips in calendar cells ────────────────────────────────────────────

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
    final combinedCount = remoteEvents.length + events.length;
    final chips = <Widget>[];

    for (final re in remoteEvents.take(2)) {
      chips.add(GestureDetector(
        onTap: onTapRemote == null ? null : () => onTapRemote!(re),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: _tripColor(re.routeId),
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
      ));
      if (chips.length >= 2) break;
    }

    if (chips.length < 2) {
      for (final le in events.take(2 - chips.length)) {
        chips.add(GestureDetector(
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
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final chip in chips)
          Padding(padding: const EdgeInsets.only(bottom: 2), child: chip),
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

// ── Add event panel ───────────────────────────────────────────────────────────

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
    final header = widget.rangeMin != widget.rangeMax
        ? '${widget.rangeMin} – ${widget.rangeMax} ${widget.monthName}'
        : '${widget.rangeMin} ${widget.monthName}';
    final canAdd = widget.titleController.text.trim().isNotEmpty;

    return Padding(
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
                    fontWeight: FontWeight.w700,
                    color: p.textMain,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onCloseForm,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: p.navBtn,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, size: 16, color: p.textMuted),
                ),
              ),
            ],
          ),
          Divider(height: 16, color: p.gridBorder),
          for (final e in widget.events.asMap().entries)
            if (e.value.day == widget.rangeMin &&
                e.value.month == widget.month &&
                e.value.year == widget.year)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                        child: Text.rich(TextSpan(
                          style: TextStyle(fontSize: 12, color: p.textMain),
                          children: [
                            TextSpan(text: e.value.title),
                            if (e.value.endDay != null)
                              TextSpan(
                                text: ' (${e.value.day}–${e.value.endDay})',
                                style: TextStyle(fontSize: 10, color: p.textMuted),
                              ),
                          ],
                        )),
                      ),
                      GestureDetector(
                        onTap: () => widget.onRemoveAt(e.key),
                        child: Icon(Icons.delete_outline_rounded,
                            size: 18, color: p.textMuted.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 6),
          TextField(
            controller: widget.titleController,
            style: TextStyle(fontSize: 13, color: scheme.onSurface),
            cursorColor: scheme.primary,
            decoration: InputDecoration(
              hintText: 'Event name...',
              filled: true,
              fillColor: p.inputFill,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: p.inputBorder, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: p.inputFocusedBorder, width: 1.5),
              ),
              hintStyle:
                  TextStyle(color: p.textMuted.withValues(alpha: 0.85)),
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
                  data: Theme.of(context).copyWith(canvasColor: p.surface),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      filled: true,
                      fillColor: p.inputFill,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: p.inputBorder, width: 1.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: p.inputBorder, width: 1.5),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: widget.newCategory,
                        isExpanded: true,
                        dropdownColor: p.surface,
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            size: 20, color: p.textMuted),
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurface),
                        items: TripAgendaCategories.keys
                            .map((k) => DropdownMenuItem(
                                  value: k,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: TripAgendaCategories
                                              .colorForKey(k),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(k,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: scheme.onSurface)),
                                    ],
                                  ),
                                ))
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
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.addButtonBg,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: p.addButtonDisabledBg,
                    disabledForegroundColor: p.addButtonDisabledFg,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: canAdd ? widget.onAdd : null,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Show helper ───────────────────────────────────────────────────────────────

Future<void> showTripAgendaCalendar(
  BuildContext context, {
  void Function(String routeId)? onOpenRouteFromCalendar,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.94,
      minChildSize: 0.55,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: TripAgendaCalendarSheet(
          onOpenRouteFromCalendar: onOpenRouteFromCalendar,
        ),
      ),
    ),
  );
}

// ── Detail action model ───────────────────────────────────────────────────────

class _DetailAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final _DetailActionStyle style;

  const _DetailAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.style,
  });

  factory _DetailAction.primary({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => _DetailAction(icon: icon, label: label, onTap: onTap, style: _DetailActionStyle.primary);

  factory _DetailAction.muted({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => _DetailAction(icon: icon, label: label, onTap: onTap, style: _DetailActionStyle.muted);

  factory _DetailAction.danger({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => _DetailAction(icon: icon, label: label, onTap: onTap, style: _DetailActionStyle.danger);
}

enum _DetailActionStyle { primary, muted, danger }

// ── Detail bottom sheet ───────────────────────────────────────────────────────

Widget _detailSheet(
  BuildContext context, {
  required _TripPalette palette,
  required Color color,
  required String title,
  required String subtitle,
  required String? destination,
  required String? dayBadge,
  required List<_DetailAction> actions,
}) {
  final tokens = Theme.of(context).extension<VacanzaTokens>() ?? VacanzaTokens.light;
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    child: Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Colored accent strip
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 2),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.textMuted.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date + day badge row
                Row(
                  children: [
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: palette.textMuted,
                      ),
                    ),
                    if (dayBadge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: color.withValues(alpha: 0.30)),
                        ),
                        child: Text(
                          dayBadge,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                // Trip title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: palette.textMain,
                    height: 1.2,
                  ),
                ),
                // Destination
                if (destination != null && destination.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.place_rounded,
                          size: 14, color: palette.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        destination,
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Divider(
                    height: 1,
                    color: tokens.cardBorder.withValues(alpha: 0.45)),
                const SizedBox(height: 12),
                // Action buttons
                for (int i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(height: 6),
                  _detailActionButton(
                    context,
                    palette: palette,
                    tokens: tokens,
                    cs: cs,
                    action: actions[i],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _detailActionButton(
  BuildContext context, {
  required _TripPalette palette,
  required VacanzaTokens tokens,
  required ColorScheme cs,
  required _DetailAction action,
}) {
  final Color bg;
  final Color fg;
  final Color? borderColor;

  switch (action.style) {
    case _DetailActionStyle.primary:
      bg = tokens.vividBlue;
      fg = Colors.white;
      borderColor = null;
    case _DetailActionStyle.muted:
      bg = tokens.actionBarInactiveBg.withValues(alpha: 0.85);
      fg = tokens.textMain;
      borderColor = tokens.cardBorder.withValues(alpha: 0.50);
    case _DetailActionStyle.danger:
      bg = cs.errorContainer.withValues(alpha: 0.45);
      fg = cs.error;
      borderColor = cs.error.withValues(alpha: 0.35);
  }

  final iconBoxColor = action.style == _DetailActionStyle.primary
      ? Colors.white.withValues(alpha: 0.20)
      : fg.withValues(alpha: 0.12);

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 1.2)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBoxColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(action.icon, size: 18, color: fg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  action.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    height: 1.2,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: fg.withValues(alpha: 0.50),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
