import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

/// Pulsing loading indicator shown at bottom-left while a route is being built in background.
class RouteLoadingPill extends StatefulWidget {
  const RouteLoadingPill({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  State<RouteLoadingPill> createState() => _RouteLoadingPillState();
}

class _RouteLoadingPillState extends State<RouteLoadingPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.12, end: 0.32).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.vacanzaTokens;
    final accent = context.mapControlAccent;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return AnimatedBuilder(
      animation: _glow,
      builder: (_, child) => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: _glow.value),
              blurRadius: 22,
              spreadRadius: 3,
            ),
          ],
        ),
        child: child!,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLight
                        ? context.lightGlassPanelColor
                        : tokens.glassBg,
                    border: Border.all(
                      color: accent.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 42,
                  height: 42,
                  child: CircularProgressIndicator(
                    color: accent,
                    strokeWidth: 2.0,
                    backgroundColor: accent.withValues(alpha: 0.10),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Icon(Icons.route_rounded, size: 18, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact reopen control for the active trip route (sheet closed).
/// Icon-only circle so it does not cover the Ask Vacanza pill; day is in the tooltip.
class RouteMiniPill extends StatelessWidget {
  final int day;
  final VoidCallback onOpen;
  final VoidCallback onClear;

  const RouteMiniPill({
    super.key,
    required this.day,
    required this.onOpen,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.vacanzaTokens;
    final accent = context.mapControlAccent;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Tooltip(
      message:
          'Last trip route · Day $day — tap to reopen sheet, long-press to remove from map',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          onLongPress: onClear,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLight ? context.lightGlassPanelColor : tokens.glassBg,
              border: Border.all(color: tokens.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLight ? 0.10 : 0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(Icons.map_rounded, size: 24, color: accent),
          ),
        ),
      ),
    );
  }
}
