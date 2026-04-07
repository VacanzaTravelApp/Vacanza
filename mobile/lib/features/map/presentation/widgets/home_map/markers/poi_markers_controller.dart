import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import '../../../../../poi_search/data/models/poi.dart';
import '../../../../../poi_search/data/models/poi_category_catalog.dart';

import 'poi_marker_bitmap_builder.dart';

class PoiMarkersController {
  PoiMarkersController(
    this._map, {
    this.onPoiTap,
  });

  final mb.MapboxMap _map;

  /// Called when the user taps a POI marker (annotation).
  final void Function(Poi poi)? onPoiTap;

  mb.PointAnnotationManager? _pointManager;

  final Map<String, mb.PointAnnotation> _byPoiId = {};
  final Map<String, Poi> _poiCache = {};
  final Map<String, Uint8List> _iconCache = {};

  mb.Cancelable? _tapCancel;

  Completer<void>? _opLock;
  int _opEpoch = 0;

  bool get isReady => _pointManager != null;

  Future<void> init() async {
    if (_pointManager != null) {
      await dispose();
    }

    final annotations = _map.annotations;
    _pointManager = await annotations.createPointAnnotationManager();

    _tapCancel?.cancel();
    _tapCancel = _pointManager!.tapEvents(onTap: _onAnnotationTap);

    log('[PoiMarkersController] init completed');
  }

  void _onAnnotationTap(mb.PointAnnotation annotation) {
    if (onPoiTap == null) return;
    String? poiId;
    for (final e in _byPoiId.entries) {
      if (e.value.id == annotation.id) {
        poiId = e.key;
        break;
      }
    }
    if (poiId == null) return;
    final poi = _poiCache[poiId];
    if (poi == null) return;
    onPoiTap!(poi);
  }

  Future<void> clear() async {
    final mgr = _pointManager;
    if (mgr == null) {
      log('[PoiMarkersController] clear: manager is null');
      return;
    }

    try {
      _byPoiId.clear();
      _poiCache.clear();
      await mgr.deleteAll();
      log('[PoiMarkersController] cleared all markers');
    } catch (e) {
      log('[PoiMarkersController] deleteAll failed: $e');
    }
  }

  String _normCategory(String raw) => raw.trim().toLowerCase();

  String _cacheKeyForCategory(String category) {
    final def = PoiCategoryCatalog.poiCategoryForRaw(category);
    return def?.key ?? 'others';
  }

  Future<Uint8List> _bitmapForCategory(String category) async {
    final key = _cacheKeyForCategory(category);

    final cached = _iconCache[key];
    if (cached != null) return cached;

    try {
      final bytes =
          await PoiMarkerBitmapBuilder.bitmapForRawCategory(category);
      _iconCache[key] = bytes;
      log('[PoiMarkersController] built icon for catalog key "$key" (${bytes.length} bytes)');
      return bytes;
    } catch (e, st) {
      log('[PoiMarkersController] bitmap build failed for "$key": $e\n$st');
      final fallback = _transparentPng1x1();
      _iconCache[key] = fallback;
      return fallback;
    }
  }

  Uint8List _transparentPng1x1() {
    return Uint8List.fromList(<int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
      0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
      0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
      0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
      0x42, 0x60, 0x82
    ]);
  }

  Future<void> setPois(List<Poi> pois) async {
    final mgr = _pointManager;
    if (mgr == null) return;

    while (_opLock != null) {
      await _opLock!.future;
    }
    final epoch = ++_opEpoch;
    final completer = Completer<void>();
    _opLock = completer;

    try {
      await _doSetPois(mgr, pois, epoch);
    } finally {
      _opLock = null;
      completer.complete();
    }
  }

  Future<void> _doSetPois(
    mb.PointAnnotationManager mgr,
    List<Poi> pois,
    int epoch,
  ) async {
    if (pois.isEmpty) {
      await clear();
      return;
    }

    // ── Phase 1: prepare bitmaps while old markers stay visible ──
    final categories = <String>{};
    for (final p in pois) {
      categories.add(_normCategory(p.category));
    }
    for (final c in categories) {
      await _bitmapForCategory(c);
    }
    if (epoch != _opEpoch) return;

    // ── Phase 2: diff — keep common, add new, remove stale ──
    final incomingById = <String, Poi>{};
    for (final poi in pois) {
      if (poi.latitude == 0.0 && poi.longitude == 0.0) continue;
      incomingById[poi.poiId] = poi;
    }
    if (incomingById.isEmpty || epoch != _opEpoch) return;

    final oldIds = _byPoiId.keys.toSet();
    final newIds = incomingById.keys.toSet();

    final toKeep = oldIds.intersection(newIds);
    final toRemoveIds = oldIds.difference(newIds).toList();
    final toAddPois = <Poi>[
      for (final id in newIds)
        if (!toKeep.contains(id)) incomingById[id]!,
    ];

    // ── Phase 3: add NEW markers first (always visible) ──
    if (toAddPois.isNotEmpty) {
      final options = <mb.PointAnnotationOptions>[];
      final addedIds = <String>[];

      for (final poi in toAddPois) {
        final cacheKey = _cacheKeyForCategory(poi.category);
        final png = _iconCache[cacheKey]!;
        options.add(
          mb.PointAnnotationOptions(
            geometry: mb.Point(
              coordinates: mb.Position(poi.longitude, poi.latitude),
            ),
            image: png,
            iconAnchor: mb.IconAnchor.BOTTOM,
            iconSize: 1.0,
          ),
        );
        addedIds.add(poi.poiId);
      }

      try {
        final created = await mgr.createMulti(options);
        if (epoch != _opEpoch) return;
        for (int i = 0; i < created.length && i < addedIds.length; i++) {
          final ann = created[i];
          if (ann != null) {
            _byPoiId[addedIds[i]] = ann;
          }
        }
      } catch (e, st) {
        log('[PoiMarkersController] createMulti FAILED: $e\n$st');
      }
    }

    if (epoch != _opEpoch) return;

    // ── Phase 4: remove STALE markers ──
    if (toRemoveIds.isNotEmpty) {
      for (final id in toRemoveIds) {
        final ann = _byPoiId.remove(id);
        if (ann != null) {
          try {
            await mgr.delete(ann);
          } catch (_) {}
        }
      }
    }

    _poiCache
      ..clear()
      ..addEntries(
        incomingById.entries.where((e) => _byPoiId.containsKey(e.key)),
      );

    log(
      '[PoiMarkersController] diff: +${toAddPois.length} '
      '-${toRemoveIds.length} =${_byPoiId.length} (kept ${toKeep.length})',
    );
  }

  Future<void> dispose() async {
    log('[PoiMarkersController] disposing...');
    _tapCancel?.cancel();
    _tapCancel = null;
    await clear();
    _pointManager = null;
    _iconCache.clear();
  }
}
