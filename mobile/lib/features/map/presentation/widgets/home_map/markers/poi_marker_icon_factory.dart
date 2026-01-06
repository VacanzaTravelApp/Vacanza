/*import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Flutter IconData -> PNG marker üretir.
/// Asset kullanmaz, runtime canvas ile çizer.
///
/// Notlar:
/// - Material icon çizimi için TextPainter kullanılır.
/// - bgColor: dairenin rengi
/// - glowEnabled: hafif parıltı (abartısız)
class PoiMarkerIconFactory {
  const PoiMarkerIconFactory();

  Future<Uint8List> buildPng({
    required IconData icon,
    required Color bgColor,
    required int sizePx,
    required int iconSizePx,
    required Color iconColor,
    bool glowEnabled = false,
    double glowBlurSigma = 10,
    double glowOpacity = 0.22,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final size = Size(sizePx.toDouble(), sizePx.toDouble());
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Glow (ince)
    if (glowEnabled) {
      final glowPaint = Paint()
        ..color = bgColor.withOpacity(glowOpacity)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, glowBlurSigma);
      canvas.drawCircle(center, radius * 0.92, glowPaint);
    }

    // Ana daire
    final bgPaint = Paint()..color = bgColor;
    canvas.drawCircle(center, radius * 0.78, bgPaint);

    // İkonu text olarak çiz (MaterialIcons font)
    final iconText = String.fromCharCode(icon.codePoint);
    final textStyle = TextStyle(
      fontSize: iconSizePx.toDouble(),
      fontFamily: icon.fontFamily,
      package: icon.fontPackage,
      color: iconColor,
    );

    final tp = TextPainter(
      text: TextSpan(text: iconText, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final iconOffset = Offset(
      center.dx - tp.width / 2,
      center.dy - tp.height / 2,
    );
    tp.paint(canvas, iconOffset);

    final picture = recorder.endRecording();
    final img = await picture.toImage(sizePx, sizePx);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }
}*/