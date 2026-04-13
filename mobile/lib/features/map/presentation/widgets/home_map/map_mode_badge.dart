import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

/// Harita butonlarının altında görünen küçük rozet.
/// Basemap (STR/DARK/SAT) veya perspektif (2D/3D) etiketi.
class MapModeBadge extends StatelessWidget {
  final String label;

  const MapModeBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final accent = context.mapControlAccent;
    // Coral (gündüz) ve mavi (gece) rozet zemini üzerinde yüksek kontrast
    const labelColor = Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: labelColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
