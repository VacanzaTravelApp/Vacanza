import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

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
