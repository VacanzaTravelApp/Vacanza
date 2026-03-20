import 'package:flutter/material.dart';

/// Custom painter for the XP progress ring (gradient arc).
class XpRingPainter extends CustomPainter {
  final double percent;
  XpRingPainter(this.percent);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 8;
    const strokeWidth = 12.0;

    // Track
    final trackPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: -1.5708, // -π/2
        endAngle: 4.7124, // 3π/2
        colors: [
          Color(0xFF0096FF),
          Color(0xFF2ECC71),
          Color(0xFFFFD166),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    const startAngle = -1.5708; // -π/2 (top)
    final sweepAngle = 6.2832 * percent; // 2π * percent

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(XpRingPainter old) => old.percent != percent;
}
