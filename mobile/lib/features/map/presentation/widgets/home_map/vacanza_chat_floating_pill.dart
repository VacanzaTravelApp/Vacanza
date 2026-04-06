import 'package:flutter/material.dart';

/// Floating “Ask Vacanza” entry — soft, airy pill above the map (bottom center).
class VacanzaChatFloatingPill extends StatelessWidget {
  const VacanzaChatFloatingPill({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  static const _accent = Color(0xFF3DA8C8);
  static const _text = Color(0xFF2D3748);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        splashColor: _accent.withValues(alpha: 0.12),
        highlightColor: _accent.withValues(alpha: 0.06),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: 0.92),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.95),
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
                color: _accent.withValues(alpha: 0.14),
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
                  color: _accent.withValues(alpha: 0.95),
                ),
                const SizedBox(width: 10),
                Text(
                  'Ask Vacanza',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: _text.withValues(alpha: 0.92),
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
