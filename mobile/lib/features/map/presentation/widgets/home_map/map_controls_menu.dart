import 'package:flutter/material.dart';

import '../../../data/models/map_basemap.dart';
import '../../../data/models/map_perspective.dart';
import 'action_icon_button.dart';
import 'map_mode_badge.dart';

/// Top-right compass button that toggles the inline controls stack.
///
/// The stack animates as if it unfolds under the button (size + fade + slide).
class MapControlsMenu extends StatefulWidget {
  const MapControlsMenu({
    super.key,
    required this.open,
    required this.onToggle,
    required this.basemap,
    required this.perspective,
    required this.isDrawing,
    required this.onToggleDrawing,
    required this.onOpenSavedPlaces,
    required this.onOpenFilters,
    required this.onOpenArMode,
    required this.onOpenBooking,
    required this.onOpenTripAgenda,
    required this.onCycleBasemap,
    required this.onTogglePerspective,
  });

  final bool open;
  final VoidCallback onToggle;

  final MapBasemap basemap;
  final MapPerspective perspective;
  final bool isDrawing;

  final VoidCallback onToggleDrawing;
  final VoidCallback onOpenSavedPlaces;
  final VoidCallback onOpenFilters;
  final VoidCallback onOpenArMode;
  final VoidCallback onOpenBooking;
  final VoidCallback onOpenTripAgenda;
  final VoidCallback onCycleBasemap;
  final VoidCallback onTogglePerspective;

  @override
  State<MapControlsMenu> createState() => _MapControlsMenuState();
}

class _MapControlsMenuState extends State<MapControlsMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.06),
      end: Offset.zero,
    ).animate(_fade);

    if (widget.open) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant MapControlsMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open == widget.open) return;
    if (widget.open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final is3D = widget.perspective == MapPerspective.mode3D;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ActionIconButton(
          tooltip: widget.open ? 'Close controls' : 'Open controls',
          icon: Icons.explore_rounded,
          isActive: widget.open,
          onPressed: widget.onToggle,
        ),
        const SizedBox(height: 12),
        IgnorePointer(
          ignoring: !widget.open,
          child: SizeTransition(
            sizeFactor: _fade,
            axisAlignment: -1,
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ActionIconButton(
                      tooltip: widget.isDrawing ? 'Drawing: ON' : 'Drawing: OFF',
                      icon: Icons.edit_rounded,
                      isActive: widget.isDrawing,
                      onPressed: widget.onToggleDrawing,
                    ),
                    const SizedBox(height: 16),
                    ActionIconButton(
                      tooltip: 'Saved Places',
                      icon: Icons.favorite_rounded,
                      onPressed: widget.onOpenSavedPlaces,
                    ),
                    const SizedBox(height: 16),
                    ActionIconButton(
                      tooltip: 'Filter POIs',
                      icon: Icons.filter_alt_rounded,
                      onPressed: widget.onOpenFilters,
                    ),
                    const SizedBox(height: 16),
                    ActionIconButton(
                      tooltip: 'Explore in AR',
                      icon: Icons.view_in_ar_rounded,
                      onPressed: widget.onOpenArMode,
                    ),
                    const SizedBox(height: 16),
                    ActionIconButton(
                      tooltip: 'Booking',
                      icon: Icons.luggage_rounded,
                      onPressed: widget.onOpenBooking,
                    ),
                    const SizedBox(height: 16),
                    _actionWithBadge(
                      tooltip: _basemapTooltip(widget.basemap),
                      icon: Icons.layers_outlined,
                      badge: widget.basemap.label,
                      onPressed: widget.onCycleBasemap,
                    ),
                    const SizedBox(height: 16),
                    _actionWithBadge(
                      tooltip: is3D ? 'Switch to 2D' : 'Switch to 3D',
                      icon: Icons.map_outlined,
                      badge: widget.perspective.label,
                      isActive: is3D,
                      onPressed: widget.onTogglePerspective,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionWithBadge({
    required String tooltip,
    required IconData icon,
    required String badge,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ActionIconButton(
          tooltip: tooltip,
          icon: icon,
          isActive: isActive,
          onPressed: onPressed,
        ),
        const SizedBox(height: 6),
        MapModeBadge(label: badge),
      ],
    );
  }

  String _basemapTooltip(MapBasemap b) {
    return switch (b) {
      MapBasemap.streets => 'Map: Streets (tap for next style)',
      MapBasemap.dark => 'Map: Dark (tap for next style)',
      MapBasemap.satellite => 'Map: Satellite (tap for next style)',
    };
  }
}
