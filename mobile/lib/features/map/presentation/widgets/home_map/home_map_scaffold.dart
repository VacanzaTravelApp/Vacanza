import 'package:flutter/material.dart';
import 'package:mobile/features/map/presentation/widgets/home_map/map_canvas_placeholder.dart';
import 'package:mobile/features/map/presentation/widgets/home_map/action_bar.dart';
import 'package:mobile/features/map/presentation/widgets/home_map/profile_badge.dart';

import '../../../data/models/map_view_mode.dart';

class HomeMapScaffold extends StatelessWidget {
  final MapViewMode mode;
  final VoidCallback onOpenMapStyle;
  final VoidCallback onToggleMode;
  final VoidCallback onRecenter;

  const HomeMapScaffold({
    super.key,
    required this.mode,
    required this.onOpenMapStyle,
    required this.onToggleMode,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: MapCanvasMapbox(),
            ),

            const Positioned(
              top: 12,
              left: 12,
              child: ProfileBadge(
                name: 'Alex',
                subtitle: 'Level 12 • Solo',
              ),
            ),

            Positioned(
              top: 90,
              right: 12,
              child: ActionBar(
                mode: mode,
                onOpenMapStyle: onOpenMapStyle,
                onToggleMode: onToggleMode,
                onRecenter: onRecenter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}