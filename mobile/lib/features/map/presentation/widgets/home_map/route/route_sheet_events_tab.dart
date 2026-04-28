import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/event_mini_card.dart';
import 'package:mobile/features/ai/data/api/ai_route_api_client.dart';
import 'package:mobile/features/map/presentation/bloc/map_bloc.dart';
import 'package:mobile/features/map/presentation/bloc/map_event.dart';

import 'route_sheet_extent.dart';

/// Events tab for a saved route day (separate [StatefulWidget] for refresh key).
class RouteSheetEventsTab extends StatefulWidget {
  final String routeId;
  final int day;
  final ScrollController scrollController;
  final DraggableScrollableController? sheetExtentController;
  final VoidCallback? onFlyToEventOnMap;

  const RouteSheetEventsTab({
    super.key,
    required this.routeId,
    required this.day,
    required this.scrollController,
    this.sheetExtentController,
    this.onFlyToEventOnMap,
  });

  @override
  State<RouteSheetEventsTab> createState() => _RouteSheetEventsTabState();
}

class _RouteSheetEventsTabState extends State<RouteSheetEventsTab> {
  int _refresh = 0;
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = context
        .read<AiRouteApiClient>()
        .getEventRecommendations(widget.routeId, day: widget.day);
  }

  @override
  void didUpdateWidget(covariant RouteSheetEventsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeId != widget.routeId || oldWidget.day != widget.day) {
      _future = context
          .read<AiRouteApiClient>()
          .getEventRecommendations(widget.routeId, day: widget.day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.vacanzaTokens;
    final accent = context.mapControlAccent;
    final _ = _refresh;

    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return CustomScrollView(
            controller: widget.scrollController,
            slivers: const [
              SliverFillRemaining(
                child: Center(child: CupertinoActivityIndicator(radius: 14)),
              ),
            ],
          );
        }
        if (!snap.hasData) {
          return CustomScrollView(
            controller: widget.scrollController,
            slivers: [
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No events found.',
                    style: TextStyle(color: tokens.textSub, fontSize: 15),
                  ),
                ),
              ),
            ],
          );
        }
        final data = snap.data!;
        final has = data['hasRecommendations'] == true;
        final events = data['events'];
        final list = events is List ? events : const [];
        if (!has || list.isEmpty) {
          return CustomScrollView(
            controller: widget.scrollController,
            slivers: [
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No events found.',
                    style: TextStyle(color: tokens.textSub, fontSize: 15),
                  ),
                ),
              ),
            ],
          );
        }

        final window = data['eventSearchWindow']?.toString();
        final isBroad = window == 'BROAD_30_DAYS';

        return CustomScrollView(
          controller: widget.scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isBroad)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Showing about a month since no specific date was provided.',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.25,
                          color: tokens.textSub,
                        ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _refresh++;
                          _future = context
                              .read<AiRouteApiClient>()
                              .getEventRecommendations(
                                widget.routeId,
                                day: widget.day,
                              );
                        });
                      },
                      child: Text(
                        'Refresh',
                        style: TextStyle(
                          color: accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 142,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 4),
                      itemCount: list.length.clamp(0, 10),
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final e = list[i];
                        if (e is! Map) return const SizedBox.shrink();
                        num? lat = e['latitude'] as num? ?? e['lat'] as num?;
                        num? lng =
                            e['longitude'] as num? ?? e['lng'] as num?;
                        return EventMiniCard(
                          name: (e['name'] ?? 'Event').toString(),
                          thumbnail: pickEventThumbnail(e),
                          startLine: formatEventStartTime(
                            e['startTime']?.toString(),
                          ),
                          venueName: e['venueName']?.toString(),
                          category: e['category']?.toString(),
                          matchedDay: int.tryParse(
                            (e['matchedDay'] ?? '').toString(),
                          ),
                          matchReason: e['matchReason']?.toString(),
                          ticketLink:
                              (e['ticketLink'] ?? e['ticket_link'])
                                  ?.toString(),
                          onTapFallback:
                              (lat != null && lng != null)
                                  ? () {
                                    widget.onFlyToEventOnMap?.call();
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
                                  : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
