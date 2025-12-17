import 'package:flutter/material.dart';

import '../../../data/models/map_view_mode.dart';
import 'action_icon_button.dart';
import 'map_mode_badge.dart';

/// Sağ taraftaki dikey action bar.
/// Task 138: 2D/3D toggle + recenter gerçek davranışa bağlanacak.
/// UI highlight: 3D moddayken toggle butonu aktif görünsün.
class ActionBar extends StatelessWidget {
  final MapViewMode mode;
  final VoidCallback onToggleMode;
  final VoidCallback onRecenter;

  // Map style bu sprintte yok dedin; istersen sonra geri ekleriz.
  const ActionBar({
    super.key,
    required this.mode,
    required this.onToggleMode,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    final is3D = mode == MapViewMode.mode3D;

    return Column(
      children: [
        // Mode butonu + altında küçük badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            ActionIconButton(
              tooltip: '2D / 3D',
              icon: Icons.map_outlined,
              isActive: is3D, // 3D aktifken highlight
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