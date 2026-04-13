import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

/// Aktif kalem / harita kontrolü ile aynı gradyan ([mapControlActiveGradientColors]).
class VacanzaChatFloatingPill extends StatelessWidget {
  const VacanzaChatFloatingPill({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final gradientColors = context.mapControlActiveGradientColors;
    final radius = BorderRadius.circular(999);

    return Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        splashColor: Colors.white.withValues(alpha: 0.15),
        highlightColor: Colors.white.withValues(alpha: 0.08),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  'Ask Vacanza',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: Colors.white.withValues(alpha: 0.98),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
