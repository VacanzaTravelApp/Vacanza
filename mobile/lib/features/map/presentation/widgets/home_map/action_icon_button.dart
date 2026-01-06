import 'package:flutter/material.dart';

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
    const blueA = Color(0xFF2F80FF);
    const blueB = Color(0xFF34B6FF);

    final bgColor = isActive
        ? null
        : Colors.white.withValues(alpha: 0.92); // eski gibi solid ama modern

    final borderColor = isActive
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.55);

    final iconColor = isActive ? Colors.white : Colors.black87;

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
                  ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [blueA, blueB],
              )
                  : null,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                // soft depth (floating)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
                // aktifken mavi glow
                if (isActive)
                  BoxShadow(
                    color: blueA.withValues(alpha: 0.35),
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