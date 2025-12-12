import 'package:flutter/material.dart';

/// Mapbox entegrasyonu gelene kadar harita alanını temsil eden placeholder.
/// Hafif gradient + grid hissi ile “map varmış” gibi durur.
///
/// Mapbox geldiğinde bu widget kaldırılıp yerine MapboxMap widget eklenecek.
class MapCanvasPlaceholder extends StatelessWidget {
  const MapCanvasPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF7FBFF),
              Color(0xFFEFF7FF),
            ],
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.7)),
            ),
            child: const Text(
              'Map placeholder (Mapbox Sprint 2)',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
        ),
      ),
    );
  }
}

/// Basit grid painter (map hissi).
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..strokeWidth = 1;

    const step = 40.0;

    // Dikey çizgiler
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Yatay çizgiler
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}