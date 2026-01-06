// freehand_painter.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class FreehandPainter extends CustomPainter {
  final List<Offset> points;

  FreehandPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    final rect = path.getBounds();
    final center = rect.center;

    const blue = Color(0xFF1447E6);
    const green = Color(0xFF00E676);

    // İç dolgu (mavi -> yeşil, hafif)
    if (points.length >= 3) {
      final fillPath = Path.from(path)..close();

      final fillShader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [
          blue.withValues(alpha: 0.14),
          green.withValues(alpha: 0.14),
        ],
        const [0.0, 1.0],
      );

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = fillShader;

      final fillGlowPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = fillShader
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10);

      canvas.drawPath(fillPath, fillGlowPaint);
      canvas.drawPath(fillPath, fillPaint);
    }

    // Stroke gradient (mavi-yeşil)
    final strokeShader = ui.Gradient.sweep(
      center,
      const [blue, green, blue],
      const [0.0, 0.55, 1.0],
    );

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = strokeShader
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 16);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = strokeShader;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant FreehandPainter oldDelegate) {
    return oldDelegate.points.length != points.length;
  }
}