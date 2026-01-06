import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/navigation/navigation_service.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:mobile/features/map/presentation/widgets/home_map/mapbox/map_canvas_mapbox.dart';
import 'package:mobile/features/map/presentation/widgets/home_map/action_bar.dart';
import 'package:mobile/features/map/presentation/widgets/home_map/profile_badge.dart';

import '../../../data/models/map_view_mode.dart';

class HomeMapScaffold extends StatelessWidget {
  final MapViewMode mode;
  final bool isDrawing;

  final VoidCallback onToggleMode;
  final VoidCallback onRecenter;
  final VoidCallback onToggleDrawing;

  /// VACANZA-188: filter panel open
  final VoidCallback onOpenFilters;

  /// Panel overlay kontrolü (HomeMapScreen yönetir)
  final bool isFiltersOpen;
  final Widget? filtersPanel;
  final VoidCallback? onCloseFilters;

  const HomeMapScaffold({
    super.key,
    required this.mode,
    required this.isDrawing,
    required this.onToggleMode,
    required this.onRecenter,
    required this.onToggleDrawing,
    required this.onOpenFilters,
    this.isFiltersOpen = false,
    this.filtersPanel,
    this.onCloseFilters,
  });

  /// VACANZA-163 Logout
  Future<void> _handleLogout(BuildContext context) async {
    try {
      await context.read<AuthRepository>().logout();
    } finally {
      NavigationService.resetToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showFilters = isFiltersOpen && filtersPanel != null;

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
                isDrawing: isDrawing,
                onToggleMode: onToggleMode,
                onRecenter: onRecenter,
                onToggleDrawing: onToggleDrawing,
                onOpenFilters: onOpenFilters,
              ),
            ),

            // ================= FILTER OVERLAY (SAĞDAN PANEL) =================
            if (showFilters) ...[
              // backdrop (dışına tıklayınca kapat)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: onCloseFilters,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.10),
                  ),
                ),
              ),

              // panel
              Positioned(
                top: 110, // ActionBar hizası + biraz boşluk
                right: 16,
                child: Material(
                  color: Colors.transparent,
                  child: filtersPanel!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}