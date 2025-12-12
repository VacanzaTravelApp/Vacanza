import 'package:flutter/material.dart';

import '../../../data/models/map_view_mode.dart';
import 'action_bar.dart';
import 'map_canvas_placeholder.dart';
import 'profile_badge.dart';

/// Map ekranının ana layout container'ı.
/// Stack ile:
/// - Ortada map placeholder
/// - Sol üst profil badge
/// - Sağda action bar
///
/// Mapbox geldiğinde sadece MapCanvasPlaceholder yerine
/// Mapbox widget'ı eklenecek, layout aynı kalacak.
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
      // Şimdilik default AppBar yok. Tasarım “map full-screen” gibi dursun.
      body: SafeArea(
        child: Stack(
          children: [
            // 1) Harita alanı placeholder
            const Positioned.fill(
              child: MapCanvasPlaceholder(),
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