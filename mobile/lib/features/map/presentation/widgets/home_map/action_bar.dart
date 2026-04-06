import 'package:flutter/material.dart';

import '../../../data/models/map_view_mode.dart';
import 'action_icon_button.dart';
import 'map_mode_badge.dart';

class ActionBar extends StatelessWidget {
  final MapViewMode mode;
  final bool isDrawing;
  final VoidCallback onToggleMode;
  final VoidCallback onRecenter;
  final VoidCallback onToggleDrawing;

  // ✅ UC1.8-MOB1: Booking entry point
  final VoidCallback onOpenBooking;

  // ✅ NEW
  final VoidCallback onOpenFilters;

  /// UC1.11 — Explore in AR entry point
  final VoidCallback onOpenArMode;

  const ActionBar({
    super.key,
    required this.mode,
    required this.isDrawing,
    required this.onToggleMode,
    required this.onRecenter,
    required this.onToggleDrawing,
    required this.onOpenBooking, // ✅ UC1.8-MOB1
    required this.onOpenFilters, // ✅ NEW
    required this.onOpenArMode, // UC1.11
  });

  @override
  Widget build(BuildContext context) {
    final is3D = mode == MapViewMode.mode3D;

    return Column(
      children: [
        ActionIconButton(
          tooltip: isDrawing ? 'Drawing: ON' : 'Drawing: OFF',
          icon: Icons.edit_rounded,
          isActive: isDrawing,
          onPressed: onToggleDrawing,
        ),
        const SizedBox(height: 16),

        // ✅ NEW: Filter button
        ActionIconButton(
          tooltip: 'Filter POIs',
          icon: Icons.layers_sharp,
          onPressed: onOpenFilters,
        ),
        const SizedBox(height: 16),

        // UC1.11: Explore in AR
        ActionIconButton(
          tooltip: 'Explore in AR',
          icon: Icons.view_in_ar_rounded,
          onPressed: onOpenArMode,
        ),
        const SizedBox(height: 16),

        // ✅ UC1.8-MOB1: Booking entry point
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
              tooltip: '2D / 3D',
              icon: Icons.map_outlined,
              isActive: is3D,
              onPressed: onToggleMode,
            ),
            Positioned(
              bottom: -10,
              left: 0,
              right: 0,
              child: Center(
                child: MapModeBadge(label: mode.label),
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