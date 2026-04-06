import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

/// Floating “Ask Vacanza” entry — soft, airy pill above the map (bottom center).
class VacanzaChatFloatingPill extends StatelessWidget {
  const VacanzaChatFloatingPill({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final accent = t.vividBlue;
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        splashColor: accent.withValues(alpha: 0.12),
        highlightColor: accent.withValues(alpha: 0.06),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: t.pillSurface,
            border: Border.all(
              color: t.pillBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 28,
                offset: const Offset(0, 10),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: t.pillShadowAccent,
                blurRadius: 20,
                offset: const Offset(0, 6),
                spreadRadius: -8,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: accent.withValues(alpha: 0.95),
                ),
                const SizedBox(width: 10),
                Text(
                  'Ask Vacanza',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: t.textMain.withValues(alpha: 0.92),
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
