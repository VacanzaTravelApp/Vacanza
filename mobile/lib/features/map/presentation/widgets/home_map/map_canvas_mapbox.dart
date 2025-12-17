import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'package:mobile/core/config/mapbox_config.dart';

import '../../../data/models/map_view_mode.dart';
import '../../bloc/map_bloc.dart';
import '../../bloc/map_event.dart';
import '../../bloc/map_state.dart';

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
      listenWhen: (prev, next) =>
      prev.viewMode != next.viewMode ||
          prev.recenterTick != next.recenterTick,
      listener: (context, state) async {
        if (_map == null) return;

        // View mode değiştiyse style + kamera uygula
        await _applyViewMode(state.viewMode);

        // Recenter tetiklendiyse başlangıç konumuna dön
        if (state.recenterTick > 0) {
          await _recenter(state.viewMode);
        }
      },
      child: MapWidget(
        key: const ValueKey('mapbox-map'),
        cameraOptions: MapboxConfig.initialCamera,
        onMapCreated: (mapboxMap) async {
          _map = mapboxMap;

          // İlk açılış: street style
          await _map!.loadStyleURI(MapboxConfig.styleStreets);

          context.read<MapBloc>().add(MapInitialized(mapboxMap));
        },
      ),
    );
  }

  /// Mode'a göre:
  /// - 2D/3D: Streets style
  /// - Satellite: Satellite style
  /// - 3D: pitch 55, diğerleri pitch 0
  Future<void> _applyViewMode(MapViewMode mode) async {
    if (_map == null) return;

    // 1) Style seç
    final String styleUri = (mode == MapViewMode.satellite)
        ? MapboxConfig.styleSatellite
        : MapboxConfig.styleStreets;

    await _map!.loadStyleURI(styleUri);

    // 2) Kamera seç
    final CameraOptions camera = (mode == MapViewMode.mode3D)
        ? MapboxConfig.camera3D
        : MapboxConfig.camera2D;

    await _map!.easeTo(
      camera,
      MapAnimationOptions(duration: 450, startDelay: 0),
    );
  }

  /// Recenter: bulunduğun mode'a göre aynı kamera presetine döner
  Future<void> _recenter(MapViewMode mode) async {
    if (_map == null) return;

    final CameraOptions camera = (mode == MapViewMode.mode3D)
        ? MapboxConfig.camera3D
        : MapboxConfig.camera2D;

    await _map!.easeTo(
      camera,
      MapAnimationOptions(duration: 550, startDelay: 0),
    );
  }
}