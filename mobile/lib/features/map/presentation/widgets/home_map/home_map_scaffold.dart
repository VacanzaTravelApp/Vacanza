// ======================= home_map_scaffold.dart =======================
// lib/features/map/presentation/widgets/home_map/home_map_scaffold.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';

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
  final bool areaDrawZoomOk;
  final bool areaDrawZoomTooHigh;

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

  /// Saved places panel entry point
  final VoidCallback onOpenSavedPlaces;

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

  /// Saved places overlay (HomeMapScreen yönetir)
  final bool isSavedPlacesOpen;
  final Widget? savedPlacesPanel;
  final VoidCallback? onCloseSavedPlaces;

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
    required this.areaDrawZoomOk,
    this.areaDrawZoomTooHigh = false,
    required this.onCycleBasemap,
    required this.onTogglePerspective,
    required this.onRecenter,
    required this.onToggleDrawing,
    required this.onOpenBooking,
    required this.onOpenTripAgenda,
    required this.onOpenChat,
    required this.onOpenSavedPlaces,
    required this.onOpenArMode,
    required this.onOpenFilters,
    required this.isControlsMenuOpen,
    required this.onToggleControlsMenu,
    required this.onCloseControlsMenu,
    this.isFiltersOpen = false,
    this.filtersPanel,
    this.onCloseFilters,
    this.isSavedPlacesOpen = false,
    this.savedPlacesPanel,
    this.onCloseSavedPlaces,
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
    final showSavedPlaces = isSavedPlacesOpen && savedPlacesPanel != null;
    final showMenu = isControlsMenuOpen;

    // normal sheet: filter kapalıyken
    final showResults =
        isResultsOpen && resultsSheet != null && !showFilters && !showSavedPlaces;
    final showRoute =
        isRouteOpen &&
        routeSheet != null &&
        !showFilters &&
        !showSavedPlaces &&
        !showResults;
    final baseMiniPill =
        showRouteMiniPill &&
        routeMiniPill != null &&
        !showFilters &&
        !showSavedPlaces &&
        !showResults;

    // blur preview: filter açıkken, sadece belirli senaryoda
    final showBlurPreview =
        showFilters && showResultsBlurUnderFilters && resultsSheet != null;

    // Route mini pill: sol altta, recenter ile aynı bottom; Ask Vacanza ortada.
    final showChatPill =
        !showResults && !showRoute && !showFilters && !showSavedPlaces && !isDrawing;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
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
              areaDrawZoomOk: areaDrawZoomOk,
              areaDrawZoomTooHigh: areaDrawZoomTooHigh,
              onToggleDrawing: onToggleDrawing,
              onOpenSavedPlaces: onOpenSavedPlaces,
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
          _RightOverlayPanel(
            show: showFilters,
            top: padding.top + 86,
            right: 16,
            onClose: onCloseFilters,
            child: Material(color: Colors.transparent, child: filtersPanel),
          ),

          // ================= SAVED PLACES OVERLAY (SAĞDAN PANEL) =================
          _RightOverlayPanel(
            show: showSavedPlaces,
            top: padding.top + 86,
            right: 16,
            onClose: onCloseSavedPlaces,
            child: savedPlacesPanel,
          ),

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

          // ================= DRAW ZOOM GATE (çizerken zoom aralığı dışına çıkınca) =================
          if (isDrawing && !areaDrawZoomOk)
            _DrawZoomGateOverlay(tooHigh: areaDrawZoomTooHigh),
        ],
      ),
    );
  }
}

/// Web `map-draw-zoom-gate` ile eşdeğer: çizim modundayken zoom aralığı dışına
/// çıkılınca haritanın üstünde beliren yarı-saydam uyarı paneli.
/// Pointer olaylarını geçirir — kullanıcı haritayı zoom'layabilir.
class _DrawZoomGateOverlay extends StatelessWidget {
  final bool tooHigh;
  const _DrawZoomGateOverlay({required this.tooHigh});

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = context.mapControlAccent;

    final title = tooHigh ? 'Zoom out to draw' : 'Zoom in to draw';
    final body = tooHigh
        ? "You're too zoomed in — zoom out a bit to select a meaningful area."
        : 'This tool is for neighbourhoods and districts. Zoom in until the warning disappears, then sketch your area.';
    final icon = tooHigh ? Icons.zoom_out_map_rounded : Icons.zoom_in_map_rounded;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
            child: Container(
              color: isLight
                  ? Colors.white.withValues(alpha: 0.18)
                  : const Color(0xFF020617).withValues(alpha: 0.42),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                      decoration: BoxDecoration(
                        color: isLight
                            ? context.lightGlassPanelColor
                            : t.glassBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isLight
                              ? accent.withValues(alpha: 0.22)
                              : t.cardBorder,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isLight ? 0.10 : 0.35,
                            ),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                          if (!isLight)
                            BoxShadow(
                              color: accent.withValues(alpha: 0.12),
                              blurRadius: 24,
                            ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Gradient accent hairline
                          SizedBox(
                            height: 3,
                            width: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: t.accentGradient,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Icon
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: accent.withValues(
                                alpha: isLight ? 0.10 : 0.14,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accent.withValues(
                                  alpha: isLight ? 0.22 : 0.32,
                                ),
                                width: 1,
                              ),
                              boxShadow: isLight
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: accent.withValues(alpha: 0.22),
                                        blurRadius: 14,
                                      ),
                                    ],
                            ),
                            child: Icon(icon, size: 26, color: accent),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: t.textMain,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            body,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: t.textSub,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RightOverlayPanel extends StatefulWidget {
  const _RightOverlayPanel({
    required this.show,
    required this.top,
    required this.right,
    required this.onClose,
    required this.child,
  });

  final bool show;
  final double top;
  final double right;
  final VoidCallback? onClose;
  final Widget? child;

  @override
  State<_RightOverlayPanel> createState() => _RightOverlayPanelState();
}

class _RightOverlayPanelState extends State<_RightOverlayPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scrimFade;
  late final Animation<Offset> _panelSlide;

  bool _mountedOverlay = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _scrimFade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _panelSlide = Tween<Offset>(
      begin: const Offset(0.075, 0),
      end: Offset.zero,
    ).animate(_scrimFade);

    _mountedOverlay = widget.show;
    if (widget.show) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant _RightOverlayPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.show == widget.show) return;

    if (widget.show) {
      setState(() => _mountedOverlay = true);
      _controller.forward();
    } else {
      _controller.reverse().whenComplete(() {
        if (!mounted) return;
        if (widget.show) return; // reopened mid-flight
        setState(() => _mountedOverlay = false);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_mountedOverlay) return const SizedBox.shrink();

    return IgnorePointer(
      ignoring: !widget.show && _controller.isDismissed,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: widget.onClose,
            ),
          ),
          Positioned(
            top: widget.top,
            right: widget.right,
            child: SlideTransition(
              position: _panelSlide,
              child: widget.child ?? const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
