import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isActive;

  const ActionIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final vivid = context.mapControlAccent;
    final activeGradient = context.mapControlActiveGradientColors;

    final bgColor = isActive ? null : t.actionBarInactiveBg;

    final borderColor = isActive
        ? vivid.withValues(alpha: 0.35)
        : t.actionBarBorder;

    final iconColor = isActive ? Colors.white : t.actionBarIcon;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: bgColor,
              gradient: isActive
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: activeGradient,
                    )
                  : null,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
                if (isActive)
                  BoxShadow(
                    color: vivid.withValues(alpha: 0.35),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
        ),
      ),
    );
  }
}