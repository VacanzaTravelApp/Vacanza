import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/navigation/navigation_service.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:mobile/features/map/presentation/widgets/home_map/map_canvas_mapbox.dart';
import 'package:mobile/features/map/presentation/widgets/home_map/action_bar.dart';
import 'package:mobile/features/map/presentation/widgets/home_map/profile_badge.dart';

import '../../../data/models/map_view_mode.dart';

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

  /// VACANZA-163
  /// Logout:
  /// - SecureStorage temizlenir
  /// - Firebase signOut
  /// - Navigation stack reset → Login
  Future<void> _handleLogout(BuildContext context) async {
    try {
      await context.read<AuthRepository>().logout();
    } finally {
      NavigationService.resetToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ================= MAP =================
            const Positioned.fill(
              child: MapCanvasMapbox(),
            ),

            // ================= PROFILE (SOL ÜST) =================
            const Positioned(
              top: 20,
              left: 16,
              child: ProfileBadge(
                name: 'Alex', // VACANZA-164
                subtitle: 'Traveler',
              ),
            ),

            // ================= LOGOUT (SAĞ ÜST) =================
            Positioned(
              top: 20,
              right: 16,
              child: IconButton(
                tooltip: 'Logout',
                icon: const Icon(Icons.logout_rounded),
                color: Colors.black87,
                onPressed: () => _handleLogout(context),
              ),
            ),

            // ================= ACTION BAR (SAĞ) =================
            Positioned(
              top: 96,
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