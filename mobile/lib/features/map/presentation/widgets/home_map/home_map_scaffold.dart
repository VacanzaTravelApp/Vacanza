import 'package:flutter/material.dart';

import '../../../data/models/map_view_mode.dart';
import 'action_bar.dart';
import 'map_canvas_mapbox.dart';
import 'profile_badge.dart';

/// Map ekranının ana layout container'ı.
/// Stack ile:
/// - Ortada gerçek Mapbox map
/// - Sol üst profil badge
/// - Sağda action bar
class HomeMapScaffold extends StatelessWidget {
  final MapViewMode mode;
  final VoidCallback onToggleMode;
  final VoidCallback onRecenter;

  const HomeMapScaffold({
    super.key,
    required this.mode,
    required this.onToggleMode,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 1) Harita alanı (Mapbox)
            const Positioned.fill(
              child: MapCanvasMapbox(),
            ),

            // 2) Sol üst profil badge
            const Positioned(
              top: 12,
              left: 12,
              child: ProfileBadge(
                name: 'Alex',
                subtitle: 'Level 12 • Solo',
              ),
            ),

            // 3) Sağ tarafta aksiyon bar
            Positioned(
              top: 90,
              right: 12,
              child: ActionBar(
                mode: mode,
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