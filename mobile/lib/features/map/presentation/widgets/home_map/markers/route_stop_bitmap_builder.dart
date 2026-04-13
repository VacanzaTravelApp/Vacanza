import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Route waypoint marker: circle + order index. Styling follows app theme (see [isLight]).
class RouteStopBitmapBuilder {
  RouteStopBitmapBuilder._();

  static final Map<String, Uint8List> _cache = <String, Uint8List>{};

  static const int _cacheVersion = 2;

  /// Web CSS width/height for the route stop badge.
  static const double _dLogical = 30;

  static double _defaultPixelRatio() {
    final v = WidgetsBinding.instance.platformDispatcher.views.first;
    return v.devicePixelRatio.clamp(1.0, 4.0);
  }

  /// [isLight] matches route polyline colors in [MapCanvasMapbox] (warm vs cyan accent).
  static Future<Uint8List> bitmapForOrder(
    int order, {
    required bool unavailable,
    required bool isLight,
    double? pixelRatio,
  }) async {
    final pr = pixelRatio ?? _defaultPixelRatio();
    final label = order <= 0 ? '?' : '$order';
    final cacheKey =
        '${label}_u$unavailable'
        '_l$isLight'
        '_${pr.toStringAsFixed(2)}_v$_cacheVersion';
    final hit = _cache[cacheKey];
    if (hit != null) {
      return hit;
    }

    final d = _dLogical * pr;
    final strokeW = (2.5 * pr).clamp(1.0, 8.0);
    final pad = strokeW + 5 * pr;
    final c = math.max(48.0, (d + pad * 2)).ceil().toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final cx = c / 2;
    final cy = c / 2;
    final radius = d / 2;

    final circleRect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    canvas.drawShadow(
      Path()..addOval(circleRect),
      Colors.black.withValues(alpha: unavailable ? 0.22 : 0.30),
      2.5 * pr,
      false,
    );

    final LinearGradient gradient;
    final Color borderColor;
    final Color textColor;

    if (unavailable) {
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF9CA3AF), Color(0xFF6B7280)],
      );
      borderColor = const Color(0xFFD1D5DB);
      textColor = Colors.white;
    } else if (isLight) {
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF97316), Color(0xFFEF4444)],
      );
      borderColor = Colors.white;
      textColor = Colors.white;
    } else {
      // Dark theme: match cyan polyline accent
      gradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
      );
      borderColor = const Color(0xFFE0F2FE);
      textColor = const Color(0xFF0C4A6E);
    }

    final fillPaint =
        Paint()
          ..shader = gradient.createShader(circleRect)
          ..isAntiAlias = true;
    canvas.drawCircle(Offset(cx, cy), radius, fillPaint);

    canvas.drawCircle(
      Offset(cx, cy),
      radius - strokeW / 2,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    final fontSize = (label.length <= 1 ? 13 : 11) * pr;
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(cx - tp.width / 2, cy - tp.height / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(c.ceil(), c.ceil());
    final bd = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bd == null) {
      throw StateError('RouteStopBitmapBuilder: PNG encode failed');
    }
    final bytes = bd.buffer.asUint8List();
    _cache[cacheKey] = bytes;
    return bytes;
  }
}
