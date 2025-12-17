import 'package:flutter/material.dart';

/// Action bar içinde kullanılan ortak ikon butonu.
/// - Yuvarlak form
/// - Shadow
/// - Tek tip padding/ölçü
/// - isActive=true ise highlight görünür (task 138)
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
    final bg = isActive ? const Color(0xFF0096FF) : Colors.white.withOpacity(0.90);
    final iconColor = isActive ? Colors.white : Colors.black87;
    final borderColor = isActive ? const Color(0xFF0096FF) : Colors.white.withOpacity(0.6);

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
              color: bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor),
          ),
        ),
      ),
    );
  }
}