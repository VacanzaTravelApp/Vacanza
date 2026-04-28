import '../models/poi.dart';

/// Mapbox stream chunk'ları için dedupe (web `mergePoiListsByStableKey` ile uyumlu).
class PoiStreamMerge {
  PoiStreamMerge._();

  static String _stableKey(Poi p) {
    final ext = p.externalId?.trim();
    if (ext != null && ext.isNotEmpty) return 'ext:$ext';
    final id = p.poiId.trim();
    if (id.isNotEmpty) return 'id:$id';
    return 'll:${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}';
  }

  static List<Poi> mergeChunk(List<Poi> accumulated, List<Poi> chunk) {
    final keys = {for (final p in accumulated) _stableKey(p)};
    final out = [...accumulated];
    for (final p in chunk) {
      final k = _stableKey(p);
      if (keys.add(k)) out.add(p);
    }
    return out;
  }
}
