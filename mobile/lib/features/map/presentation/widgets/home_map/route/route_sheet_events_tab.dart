import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/theme/app_theme.dart';
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

        return CustomScrollView(
          controller: widget.scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Align(
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
                      color: context.mapControlAccent,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            SliverList.separated(
              itemCount: list.length,
              separatorBuilder:
                  (_, __) => Divider(
                    height: 1,
                    thickness: 0.5,
                    color: tokens.cardBorder,
                  ),
              itemBuilder: (context, i) {
                final e = list[i];
                final name =
                    (e is Map && e['name'] != null)
                        ? e['name'].toString()
                        : 'Event';
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
                        await launchUrl(
                          u,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                      return;
                    }
                    if (lat != null && lng != null) {
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
                    [venue, start]
                        .whereType<String>()
                        .where((s) => s.isNotEmpty)
                        .join(' • '),
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
          ],
        );
      },
    );
  }
}
