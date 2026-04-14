import 'package:mobile/features/ar/domain/models/ar_poi.dart';
import 'package:mobile/features/poi_search/data/models/poi.dart';
import 'package:mobile/features/poi_search/data/models/poi_category_catalog.dart';

/// Minimal POI shape for `/api/feedback/poi-events` (aligned with web `buildMapPoiFeedbackPayload`).
class FeedbackPoiRef {
  const FeedbackPoiRef({
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.foursquareId,
    this.mapboxId,
  });

  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String? foursquareId;
  final String? mapboxId;

  factory FeedbackPoiRef.fromPoi(Poi p) {
    final ext = p.externalId?.trim();
    return FeedbackPoiRef(
      name: p.name,
      category: p.category,
      latitude: p.latitude,
      longitude: p.longitude,
      foursquareId: (ext == null || ext.isEmpty) ? null : ext,
      mapboxId: null,
    );
  }

  /// Same feedback identity as [fromPoi]: safe title + optional Foursquare id + coords.
  factory FeedbackPoiRef.fromArPoi(ArPoi p) {
    final safeName = PoiCategoryCatalog.safePoiTitle(
      name: p.name,
      rawCategory: p.categoryKey,
    );
    final ext = p.externalId?.trim();
    return FeedbackPoiRef(
      name: safeName,
      category: p.categoryKey,
      latitude: p.latitude,
      longitude: p.longitude,
      foursquareId: (ext == null || ext.isEmpty) ? null : ext,
      mapboxId: null,
    );
  }

  bool get hasValidCoordinates =>
      latitude.isFinite &&
      longitude.isFinite &&
      !(latitude == 0.0 && longitude == 0.0);
}
