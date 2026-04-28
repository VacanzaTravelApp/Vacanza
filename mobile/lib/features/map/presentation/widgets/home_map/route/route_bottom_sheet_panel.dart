import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/ai/data/api/ai_route_api_client.dart';
import 'package:mobile/features/ai/presentation/cubit/active_route_cubit.dart';
import 'package:mobile/features/ai/presentation/cubit/active_route_state.dart';
import 'package:mobile/features/ai/utils/route_map.dart';
import 'package:mobile/features/map/presentation/bloc/map_bloc.dart';
import 'package:mobile/features/map/presentation/bloc/map_event.dart';
import 'package:mobile/features/trip_calendar/services/ics_export_service.dart';

import 'route_sheet_events_tab.dart';
import 'route_sheet_extent.dart';
import 'route_sheet_helpers.dart';
import 'route_sheet_plan_tab.dart';
import 'route_sheet_weather.dart';
import 'route_hotel_picker_sheet.dart';
import 'route_waypoint_tile.dart';

/// Bottom sheet for the active AI route, with optional [DraggableScrollableSheet] integration.
class RouteBottomSheet extends StatefulWidget {
  final VoidCallback onClose;
  final bool initialEvents;

  /// When placed inside [DraggableScrollableSheet], pass its scroll controller.
  final ScrollController? scrollController;

  /// Same sheet's [DraggableScrollableController] so we can peek-collapse after "fly to map".
  final DraggableScrollableController? sheetExtentController;

  const RouteBottomSheet({
    super.key,
    required this.onClose,
    this.initialEvents = false,
    this.scrollController,
    this.sheetExtentController,
  });

  @override
  State<RouteBottomSheet> createState() => _RouteBottomSheetState();
}

class _RouteBottomSheetState extends State<RouteBottomSheet> {
  late int _segment;
  ScrollController? _ownedScrollController;
  int _eventsRefresh = 0;
  Future<Map<String, dynamic>>? _eventsFuture;
  String? _eventsFutureRouteId;
  int? _eventsFutureDay;

  /// 1-based stop index in the active day list when user last flew to a waypoint (Plan).
  int? _lastFlyToDisplayOrder;

  bool _hotelSaving = false;
  String? _hotelError;
  bool _calendarExporting = false;

  ScrollController get _effectiveScrollController =>
      widget.scrollController ?? _ownedScrollController!;

  @override
  void initState() {
    super.initState();
    _segment = widget.initialEvents ? 1 : 0;
    if (widget.scrollController == null) {
      _ownedScrollController = ScrollController();
    }
  }

  @override
  void dispose() {
    _ownedScrollController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RouteBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialEvents != widget.initialEvents) {
      _segment = widget.initialEvents ? 1 : 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.vacanzaTokens;
    final accent = context.mapControlAccent;
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;

    return BlocBuilder<ActiveRouteCubit, ActiveRouteState>(
      builder: (context, state) {
        final screenH = MediaQuery.sizeOf(context).height;
        final maxH = (screenH * 0.58).clamp(300.0, 680.0);

        if (state.status == ActiveRouteStatus.loading && state.route == null) {
          return SizedBox(
            height: maxH,
            child: _container(
              context,
              child: const Center(
                child: CupertinoActivityIndicator(radius: 14),
              ),
            ),
          );
        }

        if (state.status == ActiveRouteStatus.failure) {
          return SizedBox(
            height: maxH,
            child: _container(
              context,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 8, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Route',
                            style: TextStyle(
                              fontSize: isIos ? 17 : 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: isIos ? -0.4 : 0,
                              color: tokens.textMain,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: widget.onClose,
                          child: Icon(
                            CupertinoIcons.xmark,
                            color: tokens.textSub,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage ?? 'Something went wrong.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.25,
                        color: tokens.textSub,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final route = state.route;
        if (route == null) {
          return const SizedBox.shrink();
        }

        final chipDays = dayChipNumbers(route);
        final activeDay = effectiveActiveDayForRoute(route, state.activeDay);
        if (activeDay != state.activeDay &&
            activeDay >= 1 &&
            activeDay <= route.totalDays) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            context.read<ActiveRouteCubit>().setActiveDay(activeDay);
          });
        }
        final waypoints = waypointsForDay(route, activeDay);
        final routeId = state.routeId;
        final tripStart = IcsExportService.tryParseIsoDate(route.tripStartDate);

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

        Future<void> exportToCalendar() async {
          if (routeId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Save this route first to export a calendar file.'),
              ),
            );
            return;
          }
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
              // Mirrors web: route already on that day.
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

        Widget fixedHeightBody({required double height}) {
          return SizedBox(
            height: height,
            child: _container(
              context,
              child: _wrapWhenRouteBusy(
                state,
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: LayoutBuilder(
                    builder: (context, lc) {
                      final cap = lc.maxHeight;
                      final compact = cap < 380;
                      final hasWeather =
                          route.weatherForecast.isNotEmpty ||
                          route.weatherDayParts.isNotEmpty;
                      final notesRaw = route.notes?.trim();
                      final hasNotes = notesRaw != null && notesRaw.isNotEmpty;

                      const minPlanBody = 88.0;
                      final handleBlock = 5.0 + 10.0 + (compact ? 6 : 0);
                      final headerRow = 74.0;
                      final segBlock =
                          routeId != null ? (compact ? 48.0 : 58.0) : 0.0;
                      final gaps =
                          (compact ? 6.0 : 10.0) + (routeId != null ? 6 : 10);
                      var overhead =
                          handleBlock +
                          headerRow +
                          segBlock +
                          gaps +
                          minPlanBody;

                      var weatherMax = 0.0;
                      if (hasWeather) {
                        weatherMax = math.min(
                          130,
                          math.max(0, cap - overhead - (hasNotes ? 36 : 0)),
                        );
                        if (weatherMax < 44) {
                          weatherMax = 0;
                        } else {
                          overhead += weatherMax + 8;
                        }
                      }

                      var notesMaxLines = compact ? 2 : 5;
                      if (hasNotes && cap - overhead < 40) {
                        notesMaxLines = 1;
                      }

                      final segPadBottom = compact ? 4.0 : 10.0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: tokens.textSub.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          SizedBox(height: compact ? 6 : 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      route.title?.trim().isNotEmpty == true
                                          ? route.title!
                                          : 'Your AI Route',
                                      maxLines: compact ? 1 : 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize:
                                            compact
                                                ? (isIos ? 17 : 16)
                                                : (isIos ? 20 : 18),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: isIos ? -0.5 : -0.2,
                                        height: 1.15,
                                        color: tokens.textMain,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      route.destination ?? 'Destination',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: compact ? 13 : 14,
                                        color: tokens.textSub,
                                        letterSpacing: isIos ? -0.2 : 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    CupertinoButton(
                                      padding: const EdgeInsets.only(top: 2),
                                      onPressed:
                                          _calendarExporting ? null : exportToCalendar,
                                      child:
                                          _calendarExporting
                                              ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CupertinoActivityIndicator(
                                                  radius: 10,
                                                ),
                                              )
                                              : Icon(
                                                CupertinoIcons.calendar_badge_plus,
                                                color:
                                                    routeId != null
                                                        ? accent
                                                        : tokens.textSub
                                                            .withValues(alpha: 0.45),
                                                size: compact ? 23 : 25,
                                              ),
                                    ),
                                  CupertinoButton(
                                    padding: const EdgeInsets.only(top: 2),
                                    onPressed: () {
                                      final wps = allWaypointsForMap(route);
                                      final b = boundsOfWaypoints(wps);
                                      final brg = bearingFirstToLast(wps);
                                      if (b != null) {
                                        context.read<MapBloc>().add(
                                          FitRouteBoundsRequested(
                                            minLat: b.minLat,
                                            maxLat: b.maxLat,
                                            minLng: b.minLng,
                                            maxLng: b.maxLng,
                                            bearing: brg,
                                          ),
                                        );
                                      }
                                    },
                                    child: Icon(
                                      CupertinoIcons.map,
                                      color: accent,
                                      size: compact ? 24 : 26,
                                    ),
                                  ),
                                  CupertinoButton(
                                    padding: const EdgeInsets.only(top: 2),
                                    onPressed: widget.onClose,
                                    child: Icon(
                                      CupertinoIcons.xmark,
                                      color: tokens.textSub,
                                      size: compact ? 22 : 24,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (hasWeather && weatherMax > 0) ...[
                            SizedBox(height: compact ? 6 : 8),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: weatherMax,
                              ),
                              child: SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                child: RouteSheetWeather(route: route),
                              ),
                            ),
                          ],
                          if (hasNotes) ...[
                            SizedBox(height: compact ? 4 : 8),
                            Text(
                              notesRaw,
                              maxLines: notesMaxLines,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: compact ? 12 : 13,
                                height: 1.35,
                                color: tokens.textSub,
                              ),
                            ),
                          ],
                          if (routeId != null) ...[
                            SizedBox(height: compact ? 8 : 10),
                            _hotelSection(
                              context,
                              route: route,
                              routeId: routeId,
                              compact: compact,
                            ),
                          ],
                          SizedBox(height: compact ? 6 : 10),
                          if (routeId != null) ...[
                            Padding(
                              padding: EdgeInsets.only(bottom: segPadBottom),
                              child: CupertinoSlidingSegmentedControl<int>(
                                groupValue: _segment,
                                thumbColor:
                                    Theme.of(context).colorScheme.surface,
                                backgroundColor: tokens.pillSurface.withValues(
                                  alpha: 0.9,
                                ),
                                onValueChanged: (v) {
                                  if (v != null) {
                                    setState(() {
                                      _segment = v;
                                      _lastFlyToDisplayOrder = null;
                                    });
                                  }
                                },
                                children: const {
                                  0: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 9),
                                    child: Text('Plan'),
                                  ),
                                  1: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 9),
                                    child: Text('Events'),
                                  ),
                                },
                              ),
                            ),
                            Expanded(
                              child:
                                  _segment == 0
                                      ? RouteSheetPlanTab(
                                        route: route,
                                        chipDays: chipDays,
                                        activeDay: activeDay,
                                        accent: accent,
                                        waypoints: waypoints,
                                        routeId: routeId,
                                        scrollController:
                                            _effectiveScrollController,
                                        sheetExtentController:
                                            widget.sheetExtentController,
                                        onWaypointFlyDisplayOrder:
                                            (o) => setState(
                                              () => _lastFlyToDisplayOrder = o,
                                            ),
                                        onDayChipInteraction:
                                            () => setState(
                                              () =>
                                                  _lastFlyToDisplayOrder = null,
                                            ),
                                      )
                                      : RouteSheetEventsTab(
                                        routeId: routeId,
                                        day: activeDay,
                                        scrollController:
                                            _effectiveScrollController,
                                        sheetExtentController:
                                            widget.sheetExtentController,
                                        onFlyToEventOnMap:
                                            () => setState(
                                              () =>
                                                  _lastFlyToDisplayOrder = null,
                                            ),
                                      ),
                            ),
                          ] else ...[
                            Expanded(
                              child: RouteSheetPlanTab(
                                route: route,
                                chipDays: chipDays,
                                activeDay: activeDay,
                                accent: accent,
                                waypoints: waypoints,
                                routeId: null,
                                scrollController: _effectiveScrollController,
                                sheetExtentController:
                                    widget.sheetExtentController,
                                onWaypointFlyDisplayOrder:
                                    (o) => setState(
                                      () => _lastFlyToDisplayOrder = o,
                                    ),
                                onDayChipInteraction:
                                    () => setState(
                                      () => _lastFlyToDisplayOrder = null,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        }

        if (widget.scrollController != null) {
          final api = context.read<AiRouteApiClient>();
          // Cache event recommendations future to avoid spamming the endpoint on rebuilds.
          if (_segment == 1 && routeId != null) {
            if (_eventsFuture == null ||
                _eventsFutureRouteId != routeId ||
                _eventsFutureDay != activeDay) {
              _eventsFutureRouteId = routeId;
              _eventsFutureDay = activeDay;
              _eventsFuture = api.getEventRecommendations(routeId, day: activeDay);
            }
          } else {
            _eventsFuture = null;
            _eventsFutureRouteId = null;
            _eventsFutureDay = null;
          }
          return _container(
            context,
            child: _wrapWhenRouteBusy(
              state,
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FutureBuilder<Map<String, dynamic>?>(
                  key: ValueKey(
                    '${routeId}_$activeDay$_segment$_eventsRefresh',
                  ),
                  future:
                      _segment == 1 && routeId != null ? _eventsFuture : null,
                  builder: (context, eventSnap) {
                    return LayoutBuilder(
                      builder: (context, lc) {
                        final cap = lc.maxHeight;
                        final compact = cap < 380;
                        final hasWeather =
                            route.weatherForecast.isNotEmpty ||
                            route.weatherDayParts.isNotEmpty;
                        final notesRaw = route.notes?.trim();
                        final hasNotes =
                            notesRaw != null && notesRaw.isNotEmpty;

                        const minPlanBody = 88.0;
                        final handleBlock = 5.0 + 10.0 + (compact ? 6 : 0);
                        final headerRow = 74.0;
                        final segBlock =
                            routeId != null ? (compact ? 48.0 : 58.0) : 0.0;
                        final gaps =
                            (compact ? 6.0 : 10.0) + (routeId != null ? 6 : 10);
                        var overhead =
                            handleBlock +
                            headerRow +
                            segBlock +
                            gaps +
                            minPlanBody;

                        var weatherMax = 0.0;
                        if (hasWeather) {
                          weatherMax = math.min(
                            130,
                            math.max(0, cap - overhead - (hasNotes ? 36 : 0)),
                          );
                          if (weatherMax < 44) {
                            weatherMax = 0;
                          } else {
                            overhead += weatherMax + 8;
                          }
                        }

                        var notesMaxLines = compact ? 2 : 5;
                        if (hasNotes && cap - overhead < 40) {
                          notesMaxLines = 1;
                        }

                        final segPadBottom = compact ? 4.0 : 10.0;

                        final header = Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _wrapHeaderTapToExpand(
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: tokens.textSub.withValues(
                                      alpha: 0.28,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: compact ? 6 : 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _wrapHeaderTapToExpand(
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          route.title?.trim().isNotEmpty == true
                                              ? route.title!
                                              : 'Your AI Route',
                                          maxLines: compact ? 1 : 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize:
                                                compact
                                                    ? (isIos ? 17 : 16)
                                                    : (isIos ? 20 : 18),
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: isIos ? -0.5 : -0.2,
                                            height: 1.15,
                                            color: tokens.textMain,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          route.destination ?? 'Destination',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: compact ? 13 : 14,
                                            color: tokens.textSub,
                                            letterSpacing: isIos ? -0.2 : 0,
                                          ),
                                        ),
                                        if (_segment == 0) ...[
                                          Builder(
                                            builder: (context) {
                                              final next = _peekNextStopLine(
                                                waypoints,
                                              );
                                              if (next == null) {
                                                return const SizedBox.shrink();
                                              }
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    next,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize:
                                                          compact ? 12.5 : 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: accent,
                                                      letterSpacing:
                                                          isIos ? -0.2 : 0,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CupertinoButton(
                                      padding: const EdgeInsets.only(top: 2),
                                      onPressed: _calendarExporting
                                          ? null
                                          : exportToCalendar,
                                      child: _calendarExporting
                                          ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CupertinoActivityIndicator(
                                              radius: 10,
                                            ),
                                          )
                                          : Icon(
                                            CupertinoIcons.calendar_badge_plus,
                                            color: routeId != null
                                                ? accent
                                                : tokens.textSub.withValues(
                                                  alpha: 0.45,
                                                ),
                                            size: compact ? 23 : 25,
                                          ),
                                    ),
                                    CupertinoButton(
                                      padding: const EdgeInsets.only(top: 2),
                                      onPressed: () {
                                        final wps = allWaypointsForMap(route);
                                        final b = boundsOfWaypoints(wps);
                                        final brg = bearingFirstToLast(wps);
                                        if (b != null) {
                                          context.read<MapBloc>().add(
                                            FitRouteBoundsRequested(
                                              minLat: b.minLat,
                                              maxLat: b.maxLat,
                                              minLng: b.minLng,
                                              maxLng: b.maxLng,
                                              bearing: brg,
                                            ),
                                          );
                                        }
                                      },
                                      child: Icon(
                                        CupertinoIcons.map,
                                        color: accent,
                                        size: compact ? 24 : 26,
                                      ),
                                    ),
                                    CupertinoButton(
                                      padding: const EdgeInsets.only(top: 2),
                                      onPressed: widget.onClose,
                                      child: Icon(
                                        CupertinoIcons.xmark,
                                        color: tokens.textSub,
                                        size: compact ? 22 : 24,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (hasWeather && weatherMax > 0) ...[
                              SizedBox(height: compact ? 6 : 8),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: weatherMax,
                                ),
                                child: SingleChildScrollView(
                                  physics: const ClampingScrollPhysics(),
                                  child: RouteSheetWeather(route: route),
                                ),
                              ),
                            ],
                            if (hasNotes) ...[
                              SizedBox(height: compact ? 4 : 8),
                              Text(
                                notesRaw,
                                maxLines: notesMaxLines,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: compact ? 12 : 13,
                                  height: 1.35,
                                  color: tokens.textSub,
                                ),
                              ),
                            ],
                            if (routeId != null) ...[
                              SizedBox(height: compact ? 8 : 10),
                              _hotelSection(
                                context,
                                route: route,
                                routeId: routeId,
                                compact: compact,
                              ),
                            ],
                            SizedBox(height: compact ? 6 : 10),
                            if (routeId != null)
                              Padding(
                                padding: EdgeInsets.only(bottom: segPadBottom),
                                child: CupertinoSlidingSegmentedControl<int>(
                                  groupValue: _segment,
                                  thumbColor:
                                      Theme.of(context).colorScheme.surface,
                                  backgroundColor: tokens.pillSurface
                                      .withValues(alpha: 0.9),
                                  onValueChanged: (v) {
                                    if (v != null) {
                                      setState(() {
                                        _segment = v;
                                        _lastFlyToDisplayOrder = null;
                                      });
                                    }
                                  },
                                  children: const {
                                    0: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 9,
                                      ),
                                      child: Text('Plan'),
                                    ),
                                    1: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 9,
                                      ),
                                      child: Text('Events'),
                                    ),
                                  },
                                ),
                              ),
                          ],
                        );

                        return CustomScrollView(
                          controller: widget.scrollController,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            SliverToBoxAdapter(child: header),
                            if (routeId != null) ...[
                              if (_segment == 0)
                                ..._planSliversForDraggable(
                                  route: route,
                                  chipDays: chipDays,
                                  activeDay: activeDay,
                                  accent: accent,
                                  waypoints: waypoints,
                                  routeId: routeId,
                                  isIos: isIos,
                                  routeScrollController:
                                      widget.scrollController!,
                                ),
                              if (_segment == 1)
                                ..._eventsSliversForDraggable(eventSnap),
                            ] else
                              ..._planSliversForDraggable(
                                route: route,
                                chipDays: chipDays,
                                activeDay: activeDay,
                                accent: accent,
                                waypoints: waypoints,
                                routeId: null,
                                isIos: isIos,
                                routeScrollController: widget.scrollController!,
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          );
        }
        return fixedHeightBody(height: maxH);
      },
    );
  }

  Widget _wrapWhenRouteBusy(ActiveRouteState state, Widget child) {
    if (state.status != ActiveRouteStatus.loading) return child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        AbsorbPointer(absorbing: true, child: child),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoActivityIndicator(radius: 16),
                  SizedBox(height: 14),
                  Text(
                    'Updating your route…',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _wrapHeaderTapToExpand(Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => expandRouteSheetFromPeek(widget.sheetExtentController),
      child: child,
    );
  }

  Widget _hotelSection(
    BuildContext context, {
    required RouteMapModel route,
    required String routeId,
    required bool compact,
  }) {
    final tokens = context.vacanzaTokens;
    final accent = context.mapControlAccent;
    final hotel = route.selectedHotel;

    Future<void> openPicker() async {
      final routeCubit = context.read<ActiveRouteCubit>();
      setState(() {
        _hotelError = null;
      });
      final firstWp = route.days.isNotEmpty &&
              route.days[0].waypoints.isNotEmpty
          ? route.days[0].waypoints[0]
          : null;
      await RouteHotelPickerSheet.show(
        context,
        routeId: routeId,
        defaultDestination: route.destination,
        initialLat: firstWp?.latitude,
        initialLon: firstWp?.longitude,
      );
      if (!mounted) return;
      setState(() => _hotelSaving = true);
      try {
        await routeCubit.loadSavedRoute(routeId);
      } catch (_) {
        // ActiveRouteCubit already reports errors via state; keep this quiet.
      } finally {
        if (mounted) setState(() => _hotelSaving = false);
      }
    }

    Future<void> removeHotel() async {
      final api = context.read<AiRouteApiClient>();
      final routeCubit = context.read<ActiveRouteCubit>();
      setState(() {
        _hotelSaving = true;
        _hotelError = null;
      });
      try {
        await api.removeRouteHotel(routeId: routeId);
        if (!mounted) return;
        await routeCubit.loadSavedRoute(routeId);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _hotelError = 'Could not remove hotel.';
        });
      } finally {
        if (mounted) setState(() => _hotelSaving = false);
      }
    }

    final cardBg = Theme.of(context).colorScheme.surface.withValues(alpha: 0.72);
    final border = tokens.cardBorder.withValues(alpha: 0.55);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.bed_double_fill,
                size: compact ? 16 : 18,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Accommodation',
                  style: TextStyle(
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w700,
                    color: tokens.textMain,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (_hotelSaving)
                const CupertinoActivityIndicator(radius: 10)
              else
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: openPicker,
                  child: Text(
                    hotel == null ? '+ Add' : 'Change',
                    style: TextStyle(
                      color: accent,
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (_hotelError != null) ...[
            const SizedBox(height: 6),
            Text(
              _hotelError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (hotel == null)
            Text(
              'No hotel added yet.',
              style: TextStyle(
                color: tokens.textSub,
                fontSize: compact ? 12.5 : 13,
              ),
            )
          else ...[
            Text(
              hotel.hotelName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tokens.textMain,
                fontSize: compact ? 13.5 : 14.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            if (hotel.address != null && hotel.address!.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                hotel.address!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.textSub,
                  fontSize: compact ? 12 : 12.5,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (hotel.externalBookingUrl != null &&
                    hotel.externalBookingUrl!.trim().isNotEmpty)
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      final u = Uri.tryParse(hotel.externalBookingUrl!.trim());
                      if (u == null) return;
                      if (await canLaunchUrl(u)) {
                        await launchUrl(
                          u,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: Text(
                      'Book ↗',
                      style: TextStyle(
                        color: accent,
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _hotelSaving ? null : removeHotel,
                  child: Text(
                    'Remove',
                    style: TextStyle(
                      color: tokens.textSub,
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _hotelStopTile(
    RouteHotel hotel, {
    required String label,
    required bool isIos,
    required Color accent,
  }) {
    final tokens = context.vacanzaTokens;
    final hasCoords = hotel.latitude != null && hotel.longitude != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            hasCoords
                ? () {
                  collapseRouteSheetForMap(
                    widget.sheetExtentController,
                    _effectiveScrollController,
                  );
                  context.read<MapBloc>().add(
                    FlyToPoiRequested(
                      latitude: hotel.latitude!,
                      longitude: hotel.longitude!,
                      zoom: 16,
                    ),
                  );
                }
                : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.bed_double_fill,
                  size: 15,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel.hotelName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isIos ? 16 : 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: isIos ? -0.3 : 0,
                        color: tokens.textMain,
                      ),
                    ),
                    Text(
                      'Hotel · $label',
                      style: TextStyle(fontSize: 13, color: tokens.textSub),
                    ),
                  ],
                ),
              ),
              if (hasCoords)
                Icon(
                  CupertinoIcons.chevron_forward,
                  size: 18,
                  color: tokens.textSub.withValues(alpha: 0.65),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// [tappedDisplayOrder] is 1-based index in [wps] for the stop the user flew to.
  String? _peekNextStopLine(List<RouteMapWaypoint> wps) {
    final o = _lastFlyToDisplayOrder;
    if (o == null || o < 1) return null;
    if (o >= wps.length) {
      return 'Last stop for this day';
    }
    return 'Next: ${wps[o].name}';
  }

  List<Widget> _planSliversForDraggable({
    required RouteMapModel route,
    required List<int> chipDays,
    required int activeDay,
    required Color accent,
    required List<RouteMapWaypoint> waypoints,
    required String? routeId,
    required bool isIos,
    required ScrollController routeScrollController,
  }) {
    final tokens = context.vacanzaTokens;
    final hotel = route.selectedHotel;
    final divider = Divider(height: 1, thickness: 0.5, color: tokens.cardBorder);
    return [
      SliverToBoxAdapter(
        child: SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: chipDays.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final d = chipDays[i];
              final selected = d == activeDay;
              return ChoiceChip(
                label: Text('Day $d'),
                selected: selected,
                selectedColor: accent.withValues(alpha: 0.16),
                onSelected: (_) {
                  context.read<ActiveRouteCubit>().setActiveDay(d);
                  fitMapToDayBounds(context, route, d);
                  setState(() => _lastFlyToDisplayOrder = null);
                },
              );
            },
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 8)),
      if (hotel != null) ...[
        SliverToBoxAdapter(
          child: _hotelStopTile(hotel, label: 'Start', isIos: isIos, accent: accent),
        ),
        SliverToBoxAdapter(child: divider),
      ],
      if (waypoints.isEmpty)
        hotel != null
            ? SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No stops for this day.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: tokens.textSub),
                  ),
                ),
              ),
            )
            : SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No stops for this day.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: tokens.textSub),
                  ),
                ),
              ),
            )
      else
        SliverList.separated(
          itemCount: waypoints.length,
          separatorBuilder: (_, __) => divider,
          itemBuilder: (context, i) {
            final w = waypoints[i];
            return RouteWaypointTile(
              waypoint: w,
              displayOrder: i + 1,
              accent: accent,
              isIos: isIos,
              routeId: routeId,
              day: activeDay,
              sheetExtentController: widget.sheetExtentController,
              routeScrollController: routeScrollController,
              onFlyToDisplayOrder:
                  (o) => setState(() => _lastFlyToDisplayOrder = o),
            );
          },
        ),
      if (hotel != null) ...[
        SliverToBoxAdapter(child: divider),
        SliverToBoxAdapter(
          child: _hotelStopTile(hotel, label: 'End', isIos: isIos, accent: accent),
        ),
      ],
    ];
  }

  List<Widget> _eventsSliversForDraggable(
    AsyncSnapshot<Map<String, dynamic>?> snap,
  ) {
    final tokens = context.vacanzaTokens;
    if (snap.connectionState == ConnectionState.waiting) {
      return [
        const SliverFillRemaining(
          child: Center(child: CupertinoActivityIndicator(radius: 14)),
        ),
      ];
    }
    if (!snap.hasData) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Text(
              'No events found.',
              style: TextStyle(color: tokens.textSub, fontSize: 15),
            ),
          ),
        ),
      ];
    }
    final data = snap.data!;
    final has = data['hasRecommendations'] == true;
    final events = data['events'];
    final list = events is List ? events : const [];
    if (!has || list.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Text(
              'No events found.',
              style: TextStyle(color: tokens.textSub, fontSize: 15),
            ),
          ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: Align(
          alignment: Alignment.centerRight,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => setState(() => _eventsRefresh++),
            child: Text(
              'Refresh',
              style: TextStyle(color: context.mapControlAccent, fontSize: 16),
            ),
          ),
        ),
      ),
      SliverList.separated(
        itemCount: list.length,
        separatorBuilder:
            (_, __) =>
                Divider(height: 1, thickness: 0.5, color: tokens.cardBorder),
        itemBuilder: (context, i) {
          final e = list[i];
          final name =
              (e is Map && e['name'] != null) ? e['name'].toString() : 'Event';
          final venue =
              (e is Map && e['venueName'] != null)
                  ? e['venueName'].toString()
                  : null;
          final start =
              (e is Map && e['startTime'] != null)
                  ? e['startTime'].toString()
                  : null;
          final ticketLink =
              (e is Map)
                  ? (e['ticketLink'] ?? e['ticket_link'])?.toString()
                  : null;
          num? lat;
          num? lng;
          if (e is Map) {
            lat = e['latitude'] as num? ?? e['lat'] as num?;
            lng = e['longitude'] as num? ?? e['lng'] as num?;
          }
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 2,
            ),
            onTap: () async {
              if (ticketLink != null && ticketLink.isNotEmpty) {
                final u = Uri.tryParse(ticketLink);
                if (u != null && await canLaunchUrl(u)) {
                  await launchUrl(u, mode: LaunchMode.externalApplication);
                }
                return;
              }
              if (lat != null && lng != null) {
                setState(() => _lastFlyToDisplayOrder = null);
                collapseRouteSheetForMap(
                  widget.sheetExtentController,
                  widget.scrollController,
                );
                if (!context.mounted) return;
                context.read<MapBloc>().add(
                  FlyToPoiRequested(
                    latitude: lat.toDouble(),
                    longitude: lng.toDouble(),
                    zoom: 15,
                  ),
                );
              }
            },
            title: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tokens.textMain,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              [
                venue,
                start,
              ].whereType<String>().where((s) => s.isNotEmpty).join(' • '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: tokens.textSub, fontSize: 13),
            ),
            trailing: Icon(
              CupertinoIcons.arrow_up_right_square,
              size: 18,
              color: tokens.textSub,
            ),
          );
        },
      ),
    ];
  }

  Widget _container(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    final tokens = context.vacanzaTokens;
    final isLight = theme.brightness == Brightness.light;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color:
              isLight
                  ? context.lightGlassPanelColor.withValues(alpha: 0.94)
                  : tokens.glassBg.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
        ),
        child: child,
      ),
    );
  }
}
