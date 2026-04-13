// ======================= home_map_scaffold.dart =======================
// lib/features/map/presentation/widgets/home_map/home_map_scaffold.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/theme/vacanza_tokens.dart';
import 'package:mobile/features/map/presentation/widgets/home_map/mapbox/map_canvas_mapbox.dart';
import 'package:mobile/features/map/presentation/widgets/home_map/action_icon_button.dart';
import 'package:mobile/features/map/presentation/widgets/home_map/map_controls_menu.dart';
import 'package:mobile/features/map/presentation/widgets/home_map/vacanza_chat_floating_pill.dart';
import 'package:mobile/features/map/presentation/widgets/home_map/animated_route_sheet_entrance.dart';
import 'package:mobile/features/map/presentation/widgets/home_map/profile_badge.dart';
import 'package:mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mobile/features/profile/presentation/bloc/profile_state.dart';
import 'package:mobile/features/profile/presentation/screens/profile_screen.dart';

import '../../../data/models/map_basemap.dart';
import '../../../data/models/map_perspective.dart';

class HomeMapScaffold extends StatelessWidget {
  final MapBasemap basemap;
  final MapPerspective perspective;
  final bool isDrawing;

  final VoidCallback onCycleBasemap;
  final VoidCallback onTogglePerspective;
  final VoidCallback onRecenter;
  final VoidCallback onToggleDrawing;

  /// UC1.8-MOB1: booking entry point
  final VoidCallback onOpenBooking;

  /// Trip Agenda (web CalendarModal equivalent)
  final VoidCallback onOpenTripAgenda;

  /// Chatbot entry point
  final VoidCallback onOpenChat;

  /// UC1.11 — Explore in AR entry point
  final VoidCallback onOpenArMode;

  /// VACANZA-188: filter panel open
  final VoidCallback onOpenFilters;

  /// Map controls menu (top-right)
  final bool isControlsMenuOpen;
  final VoidCallback onToggleControlsMenu;
  final VoidCallback onCloseControlsMenu;

  /// Panel overlay kontrolü (HomeMapScreen yönetir)
  final bool isFiltersOpen;
  final Widget? filtersPanel;
  final VoidCallback? onCloseFilters;

  /// ✅ Results bottom sheet kontrolü (HomeMapScreen yönetir)
  final bool isResultsOpen;
  final Widget? resultsSheet;

  /// ✅ Active AI route bottom sheet (HomeMapScreen yönetir)
  final bool isRouteOpen;
  final Widget? routeSheet;

  /// ✅ Mini route pill (rota haritadan gizlendiğinde sol altta “show route”)
  final bool showRouteMiniPill;
  final Widget? routeMiniPill;

  /// ✅ Filter açıkken resultsSheet'i arkada blur preview göstermek için
  /// (sadece polygon sonrası filter açılınca true göndereceksin)
  final bool showResultsBlurUnderFilters;

  const HomeMapScaffold({
    super.key,
    required this.basemap,
    required this.perspective,
    required this.isDrawing,
    required this.onCycleBasemap,
    required this.onTogglePerspective,
    required this.onRecenter,
    required this.onToggleDrawing,
    required this.onOpenBooking,
    required this.onOpenTripAgenda,
    required this.onOpenChat,
    required this.onOpenArMode,
    required this.onOpenFilters,
    required this.isControlsMenuOpen,
    required this.onToggleControlsMenu,
    required this.onCloseControlsMenu,
    this.isFiltersOpen = false,
    this.filtersPanel,
    this.onCloseFilters,
    this.isResultsOpen = false,
    this.resultsSheet,
    this.isRouteOpen = false,
    this.routeSheet,
    this.showRouteMiniPill = false,
    this.routeMiniPill,
    this.showResultsBlurUnderFilters = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final showFilters = isFiltersOpen && filtersPanel != null;
    final showMenu = isControlsMenuOpen;

    // normal sheet: filter kapalıyken
    final showResults = isResultsOpen && resultsSheet != null && !showFilters;
    final showRoute =
        isRouteOpen && routeSheet != null && !showFilters && !showResults;
    final baseMiniPill =
        showRouteMiniPill &&
        routeMiniPill != null &&
        !showFilters &&
        !showResults;

    // blur preview: filter açıkken, sadece belirli senaryoda
    final showBlurPreview =
        showFilters && showResultsBlurUnderFilters && resultsSheet != null;

    // Route mini pill: sol altta, recenter ile aynı bottom; Ask Vacanza ortada.
    final showChatPill =
        !showResults && !showRoute && !showFilters && !isDrawing;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ================= MAP (tam ekran, safe area'yı aşar) =================
          const Positioned.fill(child: MapCanvasMapbox()),

          // ================= PROFILE (SOL ÜST) =================
          Positioned(
            top: padding.top + 12,
            left: 16,
            child: BlocBuilder<ProfileBloc, ProfileState>(
              buildWhen:
                  (prev, curr) =>
                      prev.profile != curr.profile ||
                      prev.profilePhotoBytes != curr.profilePhotoBytes,
              builder: (context, profileState) {
                final p = profileState.profile;
                final displayName =
                    p != null
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
                        builder:
                            (_) => BlocProvider.value(
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

          // ================= CONTROLS MENU (SAĞ ÜST) =================
          Positioned(
            top: padding.top + 12,
            right: 16,
            child: MapControlsMenu(
              open: showMenu,
              onToggle: onToggleControlsMenu,
              basemap: basemap,
              perspective: perspective,
              isDrawing: isDrawing,
              onToggleDrawing: onToggleDrawing,
              onOpenFilters: onOpenFilters,
              onOpenArMode: onOpenArMode,
              onOpenBooking: onOpenBooking,
              onOpenTripAgenda: onOpenTripAgenda,
              onCycleBasemap: onCycleBasemap,
              onTogglePerspective: onTogglePerspective,
            ),
          ),

          // ================= RECENTER (SAĞ ALT - SABİT) =================
          Positioned(
            right: 16,
            bottom: padding.bottom + 18,
            child: ActionIconButton(
              tooltip: 'Recenter',
              icon: Icons.my_location_rounded,
              onPressed: onRecenter,
            ),
          ),

          // ================= ROUTE MINI (sol alt, recenter ile aynı bottom) =================
          if (baseMiniPill)
            Positioned(
              left: 16,
              bottom: padding.bottom + 18,
              child: routeMiniPill!,
            ),

          // ================= ASK VACANZA (floating pill, bottom) =================
          if (showChatPill)
            Positioned(
              left: 0,
              right: 0,
              bottom: padding.bottom + 18,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: VacanzaChatFloatingPill(onPressed: onOpenChat),
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
                    child: Opacity(opacity: 0.55, child: resultsSheet!),
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
                  color:
                      Theme.of(
                        context,
                      ).extension<VacanzaTokens>()?.overlayScrim ??
                      Colors.black.withValues(alpha: 0.10),
                ),
              ),
            ),

            Positioned(
              top: padding.top + 86,
              right: 16,
              child: Material(color: Colors.transparent, child: filtersPanel!),
            ),
          ],

          // ================= RESULTS SHEET (BOTTOM) =================
          if (showResults)
            Positioned(
              left: 16,
              right: 16,
              bottom: padding.bottom + 16,
              child: resultsSheet!,
            ),

          // ================= ROUTE SHEET (BOTTOM, draggable + entrance anim) =================
          if (showRoute)
            Positioned(
              left: 16,
              right: 16,
              bottom: padding.bottom + 16,
              top: padding.top + 56,
              child: AnimatedRouteSheetEntrance(child: routeSheet!),
            ),
        ],
      ),
    );
  }
}
