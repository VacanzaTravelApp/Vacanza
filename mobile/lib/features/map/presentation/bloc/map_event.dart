import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Map ekranından gelen event'ler.
abstract class MapEvent {
  const MapEvent();
}

/// MapWidget controller hazır olunca tetiklenir.
class MapInitialized extends MapEvent {
  final MapboxMap controller;
  const MapInitialized(this.controller);
}

/// Right action bar: freehand drawing toggle
class ToggleDrawingPressed extends MapEvent {}

/// Drawing otomatik bitince kapatmak için (toggle yerine garanti kapatma)
class SetDrawingEnabled extends MapEvent {
  final bool enabled;
  SetDrawingEnabled(this.enabled);
}

/// Harita taban stilini döngüsel değiştirir: streets → dark → satellite.
class CycleBasemapPressed extends MapEvent {
  const CycleBasemapPressed();
}

/// 2D ↔ 3D (pitch + 3D binalar) — web `handleToggle2D3D`.
class TogglePerspectivePressed extends MapEvent {
  const TogglePerspectivePressed();
}

/// Uygulama gün/gece teması değişince haritayı önerilen basemap ile hizala
/// (koyu → dark, açık → streets). Kullanıcı [CycleBasemapPressed] ile yine değiştirebilir.
class SyncBasemapToAppTheme extends MapEvent {
  const SyncBasemapToAppTheme({required this.isDark});

  final bool isDark;
}

class RecenterPressed extends MapEvent {
  const RecenterPressed();
}

/// POI detay sheet: haritayı bu noktaya odakla (kuş uçuşu zoom).
class FlyToPoiRequested extends MapEvent {
  const FlyToPoiRequested({
    required this.latitude,
    required this.longitude,
    this.zoom = 16.0,
  });

  final double latitude;
  final double longitude;
  final double zoom;
}
