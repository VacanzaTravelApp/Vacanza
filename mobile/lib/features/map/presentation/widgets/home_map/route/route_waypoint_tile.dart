import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/ai/presentation/cubit/active_route_cubit.dart';
import 'package:mobile/features/ai/presentation/cubit/active_route_state.dart';
import 'package:mobile/features/ai/utils/route_map.dart';
import 'package:mobile/features/map/presentation/bloc/map_bloc.dart';
import 'package:mobile/features/map/presentation/bloc/map_event.dart';

import 'route_sheet_extent.dart';
import 'route_sheet_helpers.dart';

/// One stop row in the route plan list (tap → fly + optional sheet collapse).
class RouteWaypointTile extends StatelessWidget {
  final RouteMapWaypoint waypoint;

  /// 1-based index in the day list (matches map markers when backend order is 0-based).
  final int displayOrder;
  final Color accent;
  final bool isIos;
  final String? routeId;
  final int day;
  final DraggableScrollableController? sheetExtentController;
  final ScrollController? routeScrollController;
  final ValueChanged<int>? onFlyToDisplayOrder;

  const RouteWaypointTile({
    super.key,
    required this.waypoint,
    required this.displayOrder,
    required this.accent,
    required this.isIos,
    this.routeId,
    required this.day,
    this.sheetExtentController,
    this.routeScrollController,
    this.onFlyToDisplayOrder,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.vacanzaTokens;
    final cubit = context.read<ActiveRouteCubit>();
    final loading = cubit.state.status == ActiveRouteStatus.loading;
    final w = waypoint;
    final timeLine = routeWaypointTimeLine(w);
    final dur = w.estimatedDurationMin;
    final travel = w.travelFromPreviousMin;
    final stayText = (dur != null && dur > 0) ? 'Stay ~$dur min' : '';
    final travelText =
        (displayOrder > 1 && travel != null && travel > 0)
            ? '$travel min from previous stop'
            : '';

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () {
                onFlyToDisplayOrder?.call(displayOrder);
                collapseRouteSheetForMap(
                  sheetExtentController,
                  routeScrollController,
                );
                context.read<MapBloc>().add(
                  FlyToPoiRequested(
                    latitude: w.latitude,
                    longitude: w.longitude,
                    zoom: 16,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$displayOrder',
                        style: TextStyle(
                          fontSize: isIos ? 15 : 14,
                          fontWeight: FontWeight.w600,
                          color: tokens.textMain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  w.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: isIos ? 16 : 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: isIos ? -0.3 : 0,
                                    height: 1.2,
                                    color:
                                        w.unavailable
                                            ? tokens.textSub
                                            : tokens.textMain,
                                    decoration:
                                        w.unavailable
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                  ),
                                ),
                              ),
                              if (w.unavailable)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tokens.textSub.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Closed',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: tokens.textSub,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (timeLine.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              timeLine,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.2,
                                color: tokens.textSub,
                                letterSpacing: isIos ? -0.2 : 0,
                              ),
                            ),
                          ],
                          if (stayText.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              stayText,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.2,
                                color: tokens.textSub,
                              ),
                            ),
                          ],
                          if (travelText.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              travelText,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.2,
                                color: tokens.textSub.withValues(alpha: 0.92),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_forward,
                      size: 18,
                      color: tokens.textSub.withValues(alpha: 0.65),
                    ),
                  ],
                ),
              ),
            ),
            if (!w.unavailable) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      loading || routeId == null
                          ? null
                          : () => cubit.markWaypointClosed(
                            poiName: w.name,
                            day: day,
                          ),
                  icon: Icon(
                    Icons.store_mall_directory_outlined,
                    size: 18,
                    color: routeId == null ? tokens.textSub : accent,
                  ),
                  label: Text(
                    loading ? 'Updating…' : 'This place is closed',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: routeId == null ? tokens.textSub : accent,
                    ),
                  ),
                ),
              ),
              if (routeId == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Reporting a closed stop needs a saved route (route id from the server).',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      color: tokens.textSub,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
