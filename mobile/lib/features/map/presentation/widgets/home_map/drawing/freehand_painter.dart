// freehand_painter.dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Serbest çizim — [strokeStops] Vacanza paletinden çok renkli sweep.
class FreehandPainter extends CustomPainter {
  FreehandPainter(this.points, {required this.strokeStops})
    : assert(strokeStops.length >= 2, 'strokeStops needs at least 2 colors');

  final List<Offset> points;
  final List<Color> strokeStops;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    final rect = path.getBounds();
    final center = rect.center;

    final first = strokeStops.first;
    final last = strokeStops.last;

    if (points.length >= 3) {
      final fillPath = Path.from(path)..close();

      final fillShader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [first.withValues(alpha: 0.14), last.withValues(alpha: 0.14)],
        const [0.0, 1.0],
      );

      final fillPaint =
          Paint()
            ..style = PaintingStyle.fill
            ..shader = fillShader;

      final fillGlowPaint =
          Paint()
            ..style = PaintingStyle.fill
            ..shader = fillShader
            ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10);

      canvas.drawPath(fillPath, fillGlowPaint);
      canvas.drawPath(fillPath, fillPaint);
    }

    final sweepColors = <Color>[...strokeStops, strokeStops.first];
    final sweepStops = List<double>.generate(
      sweepColors.length,
      (i) => i / (sweepColors.length - 1),
    );

    final strokeShader = ui.Gradient.sweep(
      center,
      sweepColors,
      sweepStops,
      TileMode.clamp,
      0,
      2 * math.pi,
    );

    final glowPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..shader = strokeShader
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 16);

    final linePaint =
        Paint()
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
    return oldDelegate.points.length != points.length ||
        !listEquals(oldDelegate.strokeStops, strokeStops);
  }
}
