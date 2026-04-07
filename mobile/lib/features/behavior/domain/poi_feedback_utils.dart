import 'dart:convert';

import 'package:mobile/features/behavior/domain/feedback_poi_ref.dart';

/// FNV-1a 64 over UTF-8; must match [com.vacanza.backend.util.PoiFeedbackKeyUtil.fnv1a64Utf8].
BigInt _fnv1a64Utf8Bytes(List<int> bytes) {
  var h = BigInt.parse('14695981039346656037');
  final prime = BigInt.from(1099511628211);
  for (final b in bytes) {
    h = _u64(h ^ BigInt.from(b));
    h = _u64(h * prime);
  }
  return h;
}

BigInt _u64(BigInt x) => x & ((BigInt.one << 64) - BigInt.one);

/// Same as backend [PoiFeedbackKeyUtil.waypointIdentityKey] / web `waypointIdentityPoiKey`.
String? waypointIdentityPoiKey(String name, double lat, double lon) {
  if (!lat.isFinite || !lon.isFinite) return null;
  final n = name.trim().toLowerCase();
  final payload =
      '$n|${lat.toStringAsFixed(6)}|${lon.toStringAsFixed(6)}';
  final h = _fnv1a64Utf8Bytes(utf8.encode(payload));
  return 'wp:${h.toRadixString(16)}';
}

List<String> normalizeCategoryKeysFromString(String? category) {
  if (category == null) return const [];
  final t = category.trim();
  if (t.isEmpty) return const [];
  return [t.toLowerCase().replaceAll('-', '_')];
}

/// Keys in backend lookup order (web `poiKeysForMapPoi`).
List<String> poiKeysForFeedbackRef(FeedbackPoiRef p) {
  final keys = <String>[];
  final fs = p.foursquareId?.trim();
  if (fs != null && fs.isNotEmpty) {
    keys.add('fs:$fs');
  }
  final mb = p.mapboxId?.trim();
  if (mb != null && mb.isNotEmpty) {
    keys.add('mb:$mb');
  }
  final wp = waypointIdentityPoiKey(p.name, p.latitude, p.longitude);
  if (wp != null) keys.add(wp);
  return keys;
}

bool deriveMapPoiFavorited(
  Map<String, double> poiScores,
  FeedbackPoiRef p,
) {
  var sum = 0.0;
  for (final k in poiKeysForFeedbackRef(p)) {
    final v = poiScores[k];
    if (v != null && v.isFinite) sum += v;
  }
  return sum > 0.01;
}

/// Body for `POST /api/feedback/poi-events` (camelCase JSON).
Map<String, dynamic> buildPoiFeedbackEventBody({
  required String eventType,
  required FeedbackPoiRef p,
}) {
  final cats = normalizeCategoryKeysFromString(p.category);
  final rawName = p.name.trim();
  final m = <String, dynamic>{
    'eventType': eventType,
    'mapboxId': p.mapboxId,
    'foursquareId': p.foursquareId,
    'categoryKeys': cats.isEmpty ? null : cats,
    'waypointName': rawName.isEmpty ? null : rawName,
    'latitude': p.latitude,
    'longitude': p.longitude,
  };
  m.removeWhere((_, v) => v == null);
  return m;
}
