import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/ai/presentation/cubit/active_route_cubit.dart';
import 'package:mobile/features/ai/utils/route_map.dart';

import 'route_sheet_helpers.dart';
import 'route_waypoint_tile.dart';

/// Plan tab: day chips + waypoint list (used in fixed-height sheet and sliver builds).
class RouteSheetPlanTab extends StatelessWidget {
  final RouteMapModel route;
  final List<int> chipDays;
  final int activeDay;
  final Color accent;
  final List<RouteMapWaypoint> waypoints;
  final String? routeId;
  final ScrollController scrollController;
  final DraggableScrollableController? sheetExtentController;
  final ValueChanged<int>? onWaypointFlyDisplayOrder;
  final VoidCallback? onDayChipInteraction;

  const RouteSheetPlanTab({
    super.key,
    required this.route,
    required this.chipDays,
    required this.activeDay,
    required this.accent,
    required this.waypoints,
    this.routeId,
    required this.scrollController,
    this.sheetExtentController,
    this.onWaypointFlyDisplayOrder,
    this.onDayChipInteraction,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.vacanzaTokens;
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;

    return CustomScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
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
                    onDayChipInteraction?.call();
                  },
                );
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        if (waypoints.isEmpty)
          SliverFillRemaining(
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
            separatorBuilder:
                (_, __) => Divider(
                  height: 1,
                  thickness: 0.5,
                  color: tokens.cardBorder,
                ),
            itemBuilder: (context, i) {
              final w = waypoints[i];
              return RouteWaypointTile(
                waypoint: w,
                displayOrder: i + 1,
                accent: accent,
                isIos: isIos,
                routeId: routeId,
                day: activeDay,
                sheetExtentController: sheetExtentController,
                routeScrollController: scrollController,
                onFlyToDisplayOrder: onWaypointFlyDisplayOrder,
              );
            },
          ),
      ],
    );
  }
}
