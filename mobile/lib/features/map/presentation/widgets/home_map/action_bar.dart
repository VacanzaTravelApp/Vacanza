import 'package:flutter/material.dart';

import '../../../data/models/map_basemap.dart';
import '../../../data/models/map_perspective.dart';
import 'action_icon_button.dart';
import 'map_mode_badge.dart';

class ActionBar extends StatelessWidget {
  final MapBasemap basemap;
  final MapPerspective perspective;
  final bool isDrawing;

  /// streets → dark → satellite
  final VoidCallback onCycleBasemap;

  /// 2D ↔ 3D
  final VoidCallback onTogglePerspective;

  final VoidCallback onRecenter;
  final VoidCallback onToggleDrawing;

  final VoidCallback onOpenBooking;
  final VoidCallback onOpenFilters;
  final VoidCallback onOpenArMode;
  final VoidCallback onToggleTheme;

  const ActionBar({
    super.key,
    required this.basemap,
    required this.perspective,
    required this.isDrawing,
    required this.onCycleBasemap,
    required this.onTogglePerspective,
    required this.onRecenter,
    required this.onToggleDrawing,
    required this.onOpenBooking,
    required this.onOpenFilters,
    required this.onOpenArMode,
    required this.onToggleTheme,
  });

  String _basemapTooltip(MapBasemap b) {
    return switch (b) {
      MapBasemap.streets => 'Map: Streets (tap for next style)',
      MapBasemap.dark => 'Map: Dark (tap for next style)',
      MapBasemap.satellite => 'Map: Satellite (tap for next style)',
    };
  }

  @override
  Widget build(BuildContext context) {
    final is3D = perspective == MapPerspective.mode3D;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        ActionIconButton(
          tooltip: isDark ? 'Light mode' : 'Dark mode',
          icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          onPressed: onToggleTheme,
        ),
        const SizedBox(height: 16),

        ActionIconButton(
          tooltip: isDrawing ? 'Drawing: ON' : 'Drawing: OFF',
          icon: Icons.edit_rounded,
          isActive: isDrawing,
          onPressed: onToggleDrawing,
        ),
        const SizedBox(height: 16),

        ActionIconButton(
          tooltip: 'Filter POIs',
          icon: Icons.layers_sharp,
          onPressed: onOpenFilters,
        ),
        const SizedBox(height: 16),

        ActionIconButton(
          tooltip: 'Explore in AR',
          icon: Icons.view_in_ar_rounded,
          onPressed: onOpenArMode,
        ),
        const SizedBox(height: 16),

        ActionIconButton(
          tooltip: 'Booking',
          icon: Icons.luggage_rounded,
          onPressed: onOpenBooking,
        ),
        const SizedBox(height: 16),

        Stack(
          clipBehavior: Clip.none,
          children: [
            ActionIconButton(
              tooltip: _basemapTooltip(basemap),
              icon: Icons.layers_outlined,
              onPressed: onCycleBasemap,
            ),
            Positioned(
              bottom: -10,
              left: 0,
              right: 0,
              child: Center(
                child: MapModeBadge(label: basemap.label),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        Stack(
          clipBehavior: Clip.none,
          children: [
            ActionIconButton(
              tooltip: is3D ? 'Switch to 2D' : 'Switch to 3D',
              icon: Icons.map_outlined,
              isActive: is3D,
              onPressed: onTogglePerspective,
            ),
            Positioned(
              bottom: -10,
              left: 0,
              right: 0,
              child: Center(
                child: MapModeBadge(label: perspective.label),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        ActionIconButton(
          tooltip: 'Recenter',
          icon: Icons.my_location_rounded,
          onPressed: onRecenter,
        ),
      ],
    );
  }
}
