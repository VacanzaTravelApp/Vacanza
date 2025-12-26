import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import '../../../../../poi_search/data/models/geo_point.dart';
import '../../../../../poi_search/data/models/selected_area.dart';
import 'freehand_painter.dart';

/// Freehand polygon drawing overlay.
/// - isDrawing true iken GestureDetector aktif olur.
/// - Polygon tamamlanınca onPolygonFinished çağrılır.
/// - Drawing kapatmayı parent kontrol eder (onDisableDrawing).
class MapDrawingOverlay extends StatefulWidget {
  final bool isDrawing;
  final mb.MapboxMap? map;

  final void Function(PolygonArea polygon) onPolygonFinished;
  final VoidCallback onDisableDrawing;

  const MapDrawingOverlay({
    super.key,
    required this.isDrawing,
    required this.map,
    required this.onPolygonFinished,
    required this.onDisableDrawing,
  });

  @override
  State<MapDrawingOverlay> createState() => _MapDrawingOverlayState();
}

class _MapDrawingOverlayState extends State<MapDrawingOverlay> {
  bool _limitWarned = false;

  final List<Offset> _screenPath = [];
  final List<GeoPoint> _geoPoints = [];

  /// Finish sonrası path 1 an görünüp kaybolmasın.
  bool _keepPathOnDisableOnce = false;

  DateTime _lastSampleAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _sampleEvery = Duration(milliseconds: 35);

  @override
  void didUpdateWidget(covariant MapDrawingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Drawing mod değişimini yakala
    if (oldWidget.isDrawing != widget.isDrawing) {
      _onDrawingModeChanged(widget.isDrawing);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          // çizim
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: CustomPaint(
                painter: FreehandPainter(List<Offset>.of(_screenPath)),
              ),
            ),
          ),

          // gesture sadece drawing ON iken
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !widget.isDrawing,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (d) => unawaited(_onDrawPoint(d.localPosition)),
                onPanUpdate: (d) => unawaited(_onDrawPoint(d.localPosition)),
                onPanEnd: (_) => _onDrawEnd(),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDrawingModeChanged(bool enabled) {
    if (enabled) {
      setState(() {
        _limitWarned = false;
        _screenPath.clear();
        _geoPoints.clear();
        _keepPathOnDisableOnce = false;
      });
      return;
    }

    if (_keepPathOnDisableOnce) {
      _keepPathOnDisableOnce = false;
      _limitWarned = false;
      return;
    }

    setState(() {
      _limitWarned = false;
      _screenPath.clear();
      _geoPoints.clear();
    });
  }

  void _onDrawEnd() {
    if (_geoPoints.length >= 3) {
      final polygon = PolygonArea(List<GeoPoint>.of(_geoPoints));

      // parent'a polygonu yolla
      widget.onPolygonFinished(polygon);

      // drawing kapanırken path kaybolmasın
      _keepPathOnDisableOnce = true;

      // drawing OFF
      widget.onDisableDrawing();

      _geoPoints.clear();
      _limitWarned = false;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Polygon için en az 3 nokta gerekli.')),
      );

      setState(() {
        _screenPath.clear();
        _geoPoints.clear();
        _limitWarned = false;
      });

      widget.onDisableDrawing();
    }
  }

  Future<void> _onDrawPoint(Offset localPos) async {
    if (widget.map == null) return;

    final now = DateTime.now();
    if (now.difference(_lastSampleAt) < _sampleEvery) return;
    _lastSampleAt = now;

    if (_geoPoints.length >= 200) {
      if (!_limitWarned && mounted) {
        _limitWarned = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maksimum 200 nokta ekleyebilirsin.')),
        );
      }
      return;
    }

    final geo = await _screenToGeo(localPos);
    if (geo == null) return;

    if (_geoPoints.isNotEmpty) {
      final last = _geoPoints.last;
      final dLat = (last.lat - geo.lat).abs();
      final dLng = (last.lng - geo.lng).abs();
      if (dLat < 0.00001 && dLng < 0.00001) return;
    }

    if (!mounted) return;

    setState(() {
      _screenPath.add(localPos);
      _geoPoints.add(geo);
    });
  }

  Future<GeoPoint?> _screenToGeo(Offset localPos) async {
    try {
      final map = widget.map;
      if (map == null) return null;

      final screen = mb.ScreenCoordinate(
        x: localPos.dx,
        y: localPos.dy,
      );

      final point = await map.coordinateForPixel(screen);

      final coords = point.coordinates;
      final lng = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();

      return GeoPoint(lat: lat, lng: lng);
    } catch (_) {
      return null;
    }
  }
}