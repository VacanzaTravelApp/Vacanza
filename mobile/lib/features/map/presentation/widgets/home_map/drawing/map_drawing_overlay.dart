// map_drawing_overlay.dart
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
/// - Ekranda kalıcı polygon çizimi, activeSelectionPolygon ile yapılır (single source of truth).
class MapDrawingOverlay extends StatefulWidget {
  final bool isDrawing;
  final mb.MapboxMap? map;

  /// ✅ AreaQueryBloc’dan gelen aktif selection (varsa ekranda çizilir)
  final PolygonArea? activeSelectionPolygon;

  final void Function(PolygonArea polygon) onPolygonFinished;

  const MapDrawingOverlay({
    super.key,
    required this.isDrawing,
    required this.map,
    required this.activeSelectionPolygon,
    required this.onPolygonFinished,
  });

  @override
  State<MapDrawingOverlay> createState() => _MapDrawingOverlayState();
}

class _MapDrawingOverlayState extends State<MapDrawingOverlay> {
  bool _limitWarned = false;

  // Drawing esnasında (screen space)
  final List<Offset> _drawingScreenPath = [];
  final List<GeoPoint> _drawingGeoPoints = [];

  // Selection polygon (screen space) -> AreaQuery’den gelen polygonun ekranda çizilecek hali
  List<Offset> _selectionScreenPath = const [];

  DateTime _lastSampleAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _sampleEvery = Duration(milliseconds: 35);

  @override
  void didUpdateWidget(covariant MapDrawingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Drawing mod açıldıysa temiz başla
    if (!oldWidget.isDrawing && widget.isDrawing) {
      setState(() {
        _limitWarned = false;
        _drawingScreenPath.clear();
        _drawingGeoPoints.clear();
      });
    }

    // Active selection değiştiyse screen path’i yeniden hesapla
    if (oldWidget.activeSelectionPolygon != widget.activeSelectionPolygon ||
        oldWidget.map != widget.map) {
      unawaited(_rebuildSelectionScreenPath());
    }
  }

  @override
  Widget build(BuildContext context) {
    final showDrawingPath = widget.isDrawing && _drawingScreenPath.isNotEmpty;
    final showSelectionPath = !widget.isDrawing && _selectionScreenPath.isNotEmpty;

    // Öncelik: çizim açıkken çizim path’i görünür. Çizim kapalıysa selection polygon görünür.
    final pathToDraw = showDrawingPath
        ? _drawingScreenPath
        : (showSelectionPath ? _selectionScreenPath : const <Offset>[]);

    return Positioned.fill(
      child: Stack(
        children: [
          // çizim/polygon painter
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: CustomPaint(
                painter: FreehandPainter(List<Offset>.of(pathToDraw)),
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

  void _onDrawEnd() {
    if (_drawingGeoPoints.length >= 3) {
      final polygon = PolygonArea(List<GeoPoint>.of(_drawingGeoPoints));

      // ✅ parent'a polygonu yolla (AreaQuery + PoiSearch burada triggerlanacak)
      widget.onPolygonFinished(polygon);

      // ✅ drawing path temizle (kalıcı çizim activeSelection’dan gelecek)
      setState(() {
        _drawingScreenPath.clear();
        _drawingGeoPoints.clear();
        _limitWarned = false;
      });

      return;
    }

    // yetersiz nokta -> temizle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Polygon için en az 3 nokta gerekli.')),
    );

    setState(() {
      _drawingScreenPath.clear();
      _drawingGeoPoints.clear();
      _limitWarned = false;
    });
  }

  Future<void> _onDrawPoint(Offset localPos) async {
    if (widget.map == null) return;

    final now = DateTime.now();
    if (now.difference(_lastSampleAt) < _sampleEvery) return;
    _lastSampleAt = now;

    if (_drawingGeoPoints.length >= 200) {
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

    if (_drawingGeoPoints.isNotEmpty) {
      final last = _drawingGeoPoints.last;
      final dLat = (last.lat - geo.lat).abs();
      final dLng = (last.lng - geo.lng).abs();
      if (dLat < 0.00001 && dLng < 0.00001) return;
    }

    if (!mounted) return;

    setState(() {
      _drawingScreenPath.add(localPos);
      _drawingGeoPoints.add(geo);
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

  Future<void> _rebuildSelectionScreenPath() async {
    final map = widget.map;
    final polygon = widget.activeSelectionPolygon;

    if (map == null || polygon == null || polygon.points.isEmpty) {
      if (!mounted) return;
      setState(() => _selectionScreenPath = const []);
      return;
    }

    final List<Offset> newPath = [];

    // Polygon points -> screen points
    for (final p in polygon.points) {
      final screen = await _geoToScreen(p);
      if (screen != null) newPath.add(screen);
    }

    // kapatmak için ilk noktayı sona ekle (görsel olarak)
    if (newPath.length >= 2) {
      newPath.add(newPath.first);
    }

    if (!mounted) return;
    setState(() => _selectionScreenPath = List.unmodifiable(newPath));
  }

  Future<Offset?> _geoToScreen(GeoPoint geo) async {
    try {
      final map = widget.map;
      if (map == null) return null;

      final mb.ScreenCoordinate sc = await map.pixelForCoordinate(
        mb.Point(
          coordinates: mb.Position(geo.lng, geo.lat), // ✅ lng, lat
        ),
      );

      return Offset(sc.x.toDouble(), sc.y.toDouble());
    } catch (_) {
      return null;
    }
  }
}