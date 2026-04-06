// ======================= home_map_scaffold.dart =======================
// lib/features/map/presentation/widgets/home_map/home_map_scaffold.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/navigation/navigation_service.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:mobile/features/map/presentation/widgets/home_map/mapbox/map_canvas_mapbox.dart';
import 'package:mobile/features/map/presentation/widgets/home_map/action_bar.dart';
import 'package:mobile/features/map/presentation/widgets/home_map/profile_badge.dart';
import 'package:mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mobile/features/profile/presentation/bloc/profile_state.dart';
import 'package:mobile/features/profile/presentation/screens/profile_screen.dart';

import '../../../data/models/map_view_mode.dart';

class HomeMapScaffold extends StatelessWidget {
  final MapViewMode mode;
  final bool isDrawing;

  final VoidCallback onToggleMode;
  final VoidCallback onRecenter;
  final VoidCallback onToggleDrawing;

  /// UC1.8-MOB1: booking entry point
  final VoidCallback onOpenBooking;

  /// Chatbot entry point
  final VoidCallback onOpenChat;

  /// UC1.11 — Explore in AR entry point
  final VoidCallback onOpenArMode;

  /// VACANZA-188: filter panel open
  final VoidCallback onOpenFilters;

  /// Panel overlay kontrolü (HomeMapScreen yönetir)
  final bool isFiltersOpen;
  final Widget? filtersPanel;
  final VoidCallback? onCloseFilters;

  /// ✅ Results bottom sheet kontrolü (HomeMapScreen yönetir)
  final bool isResultsOpen;
  final Widget? resultsSheet;

  /// ✅ Filter açıkken resultsSheet'i arkada blur preview göstermek için
  /// (sadece polygon sonrası filter açılınca true göndereceksin)
  final bool showResultsBlurUnderFilters;

  const HomeMapScaffold({
    super.key,
    required this.mode,
    required this.isDrawing,
    required this.onToggleMode,
    required this.onRecenter,
    required this.onToggleDrawing,
    required this.onOpenBooking,
    required this.onOpenChat,
    required this.onOpenArMode,
    required this.onOpenFilters,
    this.isFiltersOpen = false,
    this.filtersPanel,
    this.onCloseFilters,
    this.isResultsOpen = false,
    this.resultsSheet,
    this.showResultsBlurUnderFilters = false,
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
    final padding = MediaQuery.of(context).padding;
    final showFilters = isFiltersOpen && filtersPanel != null;

    // normal sheet: filter kapalıyken
    final showResults = isResultsOpen && resultsSheet != null && !showFilters;

    // blur preview: filter açıkken, sadece belirli senaryoda
    final showBlurPreview =
        showFilters && showResultsBlurUnderFilters && resultsSheet != null;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ================= MAP (tam ekran, safe area'yı aşar) =================
          const Positioned.fill(
            child: MapCanvasMapbox(),
          ),

          // ================= PROFILE (SOL ÜST) =================
          Positioned(
            top: padding.top + 12,
            left: 16,
            child: BlocBuilder<ProfileBloc, ProfileState>(
              buildWhen: (prev, curr) =>
                  prev.profile != curr.profile ||
                  prev.profilePhotoBytes != curr.profilePhotoBytes,
              builder: (context, profileState) {
                final p = profileState.profile;
                final displayName = p != null
                    ? (p.displayName.trim().isNotEmpty
                        ? p.displayName
                        : p.displayNameFallback)
                    : '—';
                final profileBloc = context.read<ProfileBloc>();
                return ProfileBadge(
                  name: displayName,
                  subtitle: 'Traveler',
                  profilePhotoBytes: profileState.profilePhotoBytes,
                  imageUrl: p?.profileImageUrl,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: profileBloc,
                          child: const ProfileScreen(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ================= LOGOUT (SAĞ ÜST) =================
          Positioned(
            top: padding.top + 12,
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
            top: padding.top + 72,
            right: 12,
            child: ActionBar(
              mode: mode,
              isDrawing: isDrawing,
              onToggleMode: onToggleMode,
              onRecenter: onRecenter,
              onToggleDrawing: onToggleDrawing,
              onOpenBooking: onOpenBooking,
              onOpenChat: onOpenChat,
              onOpenFilters: onOpenFilters,
              onOpenArMode: onOpenArMode,
            ),
          ),

          // ================= RESULTS SHEET (BLUR PREVIEW UNDER FILTER) =================
          if (showBlurPreview)
            Positioned(
              left: 16,
              right: 16,
              bottom: padding.bottom + 16,
              child: IgnorePointer(
                ignoring: true,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 2.2, sigmaY: 2.2),
                    child: Opacity(
                      opacity: 0.55,
                      child: resultsSheet!,
                    ),
                  ),
                ),
              ),
            ),

          // ================= FILTER OVERLAY (SAĞDAN PANEL) =================
          if (showFilters) ...[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: onCloseFilters,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.10),
                ),
              ),
            ),

            Positioned(
              top: padding.top + 86,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: filtersPanel!,
              ),
            ),
          ],

          // ================= RESULTS SHEET (BOTTOM) =================
          if (showResults) resultsSheet!,
        ],
      ),
    );
  }
}