import 'package:flutter/material.dart';

import '../../../data/models/map_view_mode.dart';
import 'action_icon_button.dart';
import 'map_mode_badge.dart';

/// Sağ taraftaki dikey action bar.
/// Bu task kapsamında sadece UI iskeleti.
/// - Map style
/// - Mode toggle (2D/3D/SAT)
/// - Recenter
class ActionBar extends StatelessWidget {
  final MapViewMode mode;
  final VoidCallback onOpenMapStyle;
  final VoidCallback onToggleMode;
  final VoidCallback onRecenter;

  const ActionBar({
    super.key,
    required this.mode,
    required this.onOpenMapStyle,
    required this.onToggleMode,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ActionIconButton(
          tooltip: 'Map style',
          icon: Icons.layers_outlined,
          onPressed: onOpenMapStyle,
        ),
        const SizedBox(height: 12),

        // Mode butonu + altında küçük badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            ActionIconButton(
              tooltip: '2D / 3D / Satellite',
              icon: Icons.map_outlined,
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