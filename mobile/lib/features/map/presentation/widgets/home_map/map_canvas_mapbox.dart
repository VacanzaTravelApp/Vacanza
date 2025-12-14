import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'package:mobile/core/config/mapbox_config.dart';

import '../../../data/models/map_view_mode.dart';
import '../../bloc/map_bloc.dart';
import '../../bloc/map_event.dart';
import '../../bloc/map_state.dart';

/// Gerçek Mapbox harita widget'ı.
/// - Map oluşturulunca controller alınır ve MapInitialized dispatch edilir.
/// - BLoC state değişince (2D/3D, recenter) kamera burada değiştirilir.
///
/// Not: Kamera/animasyon gibi side-effect işleri bloc yerine widget tarafında yapılır.
class MapCanvasMapbox extends StatefulWidget {
  const MapCanvasMapbox({super.key});

  @override
  State<MapCanvasMapbox> createState() => _MapCanvasMapboxState();
}

class _MapCanvasMapboxState extends State<MapCanvasMapbox> {
  MapboxMap? _map;

  @override
  Widget build(BuildContext context) {
    return BlocListener<MapBloc, MapState>(
      listenWhen: (prev, next) {
        // Sadece gerçekten işimiz olan değişikliklerde tetiklenelim.
        return prev.viewMode != next.viewMode ||
            prev.recenterTick != next.recenterTick;
      },
      listener: (context, state) async {
        if (_map == null) return; // controller yoksa crash yok

        // 2D / 3D geçişi -> pitch değiştir
        await _applyViewMode(state.viewMode);

        // recenter -> başlangıç kamerasına dön
        // (recenterTick artınca burası tetiklenir)
        if (state.recenterTick > 0) {
          await _recenter(state.viewMode);
        }
      },
      child: MapWidget(
        key: const ValueKey('mapbox-map'),
        cameraOptions: MapboxConfig.initialCamera,
        onMapCreated: (mapboxMap) {
          _map = mapboxMap;
          context.read<MapBloc>().add(MapInitialized(mapboxMap));
        },
      ),
    );
  }

  /// Mode'a göre kamera pitch ayarlar (2D: 0, 3D: 55).
  Future<void> _applyViewMode(MapViewMode mode) async {
    if (_map == null) return;

    final camera = (mode == MapViewMode.mode3D)
        ? MapboxConfig.camera3D
        : MapboxConfig.camera2D;

    // Yumuşak geçiş için easeTo kullanıyoruz.
    await _map!.easeTo(
      camera,
      MapAnimationOptions(
        duration: 450, // ms
        startDelay: 0,
      ),
    );
  }

  /// Recenter: başlangıç konumuna dönerken, mevcut mode'u da korur.
  Future<void> _recenter(MapViewMode mode) async {
    if (_map == null) return;

    final camera = (mode == MapViewMode.mode3D)
        ? MapboxConfig.camera3D
        : MapboxConfig.camera2D;

    await _map!.easeTo(
      camera,
      MapAnimationOptions(
        duration: 550,
        startDelay: 0,
      ),
    );
  }
}