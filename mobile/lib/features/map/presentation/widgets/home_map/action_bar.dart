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

  const ActionBar({
    super.key,
    required this.mode,
    required this.isDrawing,
    required this.onToggleMode,
    required this.onRecenter,
    required this.onToggleDrawing,
  });

  @override
  Widget build(BuildContext context) {
    final is3D = mode == MapViewMode.mode3D;

    return Column(
      children: [
        // ✅ Drawing toggle (yuvarlak action button)
        ActionIconButton(
          tooltip: isDrawing ? 'Drawing: ON' : 'Drawing: OFF',
          icon: Icons.edit_rounded,
          isActive: isDrawing,
          onPressed: onToggleDrawing,
        ),
        const SizedBox(height: 16),

        // Mode butonu + altında küçük badge
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