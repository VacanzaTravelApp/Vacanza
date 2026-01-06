import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class PoiMarkerIconFactory {
  const PoiMarkerIconFactory();

  static final Map<String, Uint8List> _cache = <String, Uint8List>{};

  static void clearCache() => _cache.clear();

  Future<Uint8List> buildPng({
    required IconData icon,
    required Color bgColor,
    int sizePx = 96,
    double iconScale = 0.55, // 0.5-0.65 arası
    Color iconColor = Colors.white,

    // Glow
    bool enableGlow = true,
    double glowSigma = 12,
    double glowOpacity = 0.26,

    // Glow kırpılmasın diye padding
    double padRatio = 0.18,
  }) async {
    final cacheKey = [
      icon.codePoint,
      icon.fontFamily,
      icon.fontPackage,
      bgColor.value,
      sizePx,
      iconScale,
      iconColor.value,
      enableGlow,
      glowSigma,
      glowOpacity,
      padRatio,
    ].join('_');

    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final s = sizePx.toDouble();
    final center = Offset(s / 2, s / 2);

    final pad = s * padRatio;
    final radius = (s / 2) - pad;

    // 1) Glow (ince)
    if (enableGlow) {
      final glowPaint = Paint()
        ..color = bgColor.withOpacity(glowOpacity)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, glowSigma);

      canvas.drawCircle(center, radius * 1.18, glowPaint);
    }

    // 2) Arka daire
    final bgPaint = Paint()..color = bgColor;
    canvas.drawCircle(center, radius, bgPaint);

    // 3) Icon (Material Icons glyph)
    final iconText = String.fromCharCode(icon.codePoint);

    final tp = TextPainter(
      text: TextSpan(
        text: iconText,
        style: TextStyle(
          fontSize: s * iconScale,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: iconColor,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final iconOffset = Offset(
      center.dx - (tp.width / 2),
      center.dy - (tp.height / 2),
    );
    tp.paint(canvas, iconOffset);

    final picture = recorder.endRecording();
    final img = await picture.toImage(sizePx, sizePx);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);

    final png = bytes!.buffer.asUint8List();
    _cache[cacheKey] = png;
    return png;
  }
}