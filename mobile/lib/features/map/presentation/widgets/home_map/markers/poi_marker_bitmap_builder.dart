import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../../poi_search/data/models/poi_category_catalog.dart';

/// Web [MapPage.jsx] POI marker: 32×32 kutu, `borderRadius: 50% 50% 50% 0` → **sol alt** keskin köşe,
/// `rotate(-45deg)`, `fill`, `2.5px` beyaz border. Ortadaki ikon [PoiCategoryCatalog.iconData] — filtre paneliyle aynı.
class PoiMarkerBitmapBuilder {
  PoiMarkerBitmapBuilder._();

  static final Map<String, Uint8List> _cache = <String, Uint8List>{};

  /// Katalog / pin geometrisi değişince önbelleği kır.
  static const int _cacheVersion = 3;

  /// Web CSS pikseli; pin karesi bu kenar uzunluğunda.
  static const double _designSquare = 32;

  static double _defaultPixelRatio() {
    final v = WidgetsBinding.instance.platformDispatcher.views.first;
    return v.devicePixelRatio.clamp(1.0, 4.0);
  }

  /// Ham kategori stringinden (backend / Mapbox) pin görüntüsü üretir.
  static Future<Uint8List> bitmapForRawCategory(
    String rawCategory, {
    double? pixelRatio,
  }) async {
    final pr = pixelRatio ?? _defaultPixelRatio();
    final def = PoiCategoryCatalog.poiCategoryForRaw(rawCategory);
    final cacheKey =
        '${def?.key ?? 'others'}_${pr.toStringAsFixed(2)}_v$_cacheVersion';
    final hit = _cache[cacheKey];
    if (hit != null) return hit;

    final others = PoiCategoryCatalog.definitionForUiKey('others')!;
    final fillColor = def?.fillColor ?? others.fillColor;
    final iconData = def?.iconData ?? others.iconData!;

    final bytes = await _rasterize(
      fillColor: fillColor,
      iconData: iconData,
      pixelRatio: pr,
    );
    _cache[cacheKey] = bytes;
    return bytes;
  }

  static Future<Uint8List> _rasterize({
    required Color fillColor,
    required IconData iconData,
    required double pixelRatio,
  }) async {
    final d = _designSquare * pixelRatio;
    final strokeW = (2.5 * pixelRatio).clamp(1.0, 8.0);
    final pad = strokeW * 2 + pixelRatio * 4;
    final c = math.max(64.0, (d * math.sqrt2 + pad)).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final cx = c / 2;
    final cy = c / 2;

    canvas.save();
    canvas.translate(cx, cy);
    // Web `transform: rotate(-45deg)` — sol alt köşe keskin (CSS sırası TL TR BR yuvarlak, BL 0).
    canvas.rotate(-math.pi / 4);

    final rect = Rect.fromCenter(center: Offset.zero, width: d, height: d);
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: Radius.circular(d / 2),
      topRight: Radius.circular(d / 2),
      bottomRight: Radius.circular(d / 2),
      bottomLeft: Radius.zero,
    );

    final fillPaint = Paint()..color = fillColor;
    final strokePaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..isAntiAlias = true;

    canvas.drawShadow(
      Path()..addRRect(rrect),
      Colors.black.withValues(alpha: 0.35),
      3 * pixelRatio,
      false,
    );
    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, strokePaint);
    canvas.restore();

    _paintMaterialIcon(
      canvas: canvas,
      center: Offset(cx, cy - pixelRatio),
      iconData: iconData,
      pixelRatio: pixelRatio,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(c, c);
    final bd = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bd == null) {
      throw StateError('PoiMarkerBitmapBuilder: PNG encode failed');
    }
    return bd.buffer.asUint8List();
  }

  /// Filtre satırındaki [IconData] ile birebir (Material, beyaz dolgu).
  static void _paintMaterialIcon({
    required Canvas canvas,
    required Offset center,
    required IconData iconData,
    required double pixelRatio,
  }) {
    final fontSize = (18 * pixelRatio).clamp(14.0, 36.0);
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.white,
          fontFamily: iconData.fontFamily,
          package: iconData.fontPackage,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }
}
