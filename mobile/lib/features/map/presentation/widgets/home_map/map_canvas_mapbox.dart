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
      prev.viewMode != next.viewMode || prev.recenterTick != next.recenterTick,
      listener: (context, state) async {
        if (_map == null) return;

        // Mode değiştiyse style + config + camera uygula
        if (state.viewMode != context.read<MapBloc>().state.viewMode) {
          await _applyViewMode(state.viewMode);
        } else {
          // Yine de güvenli: viewMode aynı olsa bile listener buraya düşebilir
          await _applyViewMode(state.viewMode);
        }

        // Recenter tetiklendiyse preset kameraya dön
        if (state.recenterTick != 0) {
          await _recenter(state.viewMode);
        }
      },
      child: MapWidget(
        key: const ValueKey('mapbox-map'),
        cameraOptions: MapboxConfig.initialCamera,
        styleUri: MapboxConfig.styleStandard, // ilk açılış
        onMapCreated: (mapboxMap) async {
          _map = mapboxMap;

          // İlk açılışta: 2D varsay
          await _applyViewMode(MapViewMode.mode2D);

          // Bloc'a controller hazır sinyali
          if (mounted) {
            context.read<MapBloc>().add(MapInitialized(mapboxMap));
          }
        },
      ),
    );
  }

  /// ✅ Mode'a göre:
  /// - 2D: Standard + show3dObjects=false + pitch=0
  /// - 3D: Standard + show3dObjects=true  + pitch=60 + zoom=16
  /// - SAT: Standard Satellite (istersen show3dObjects kapalı bırak)
  Future<void> _applyViewMode(MapViewMode mode) async {
    if (_map == null) return;

    // 1) Style seç
    final String styleUri = (mode == MapViewMode.satellite)
        ? MapboxConfig.styleStandardSatellite
        : MapboxConfig.styleStandard;

    // Style değişecekse önce load et
    await _map!.loadStyleURI(styleUri);

    // 2) Standard style config (basemap import config)
    // Mapbox örneği bu şekilde config set ediyor.  [oai_citation:1‡GitHub](https://raw.githubusercontent.com/mapbox/mapbox-maps-flutter/main/example/lib/standard_style_import_example.dart)
    // Config seçenekleri dokümantasyonda Standard "basemap" import’unda anlatılıyor.  [oai_citation:2‡Mapbox](https://docs.mapbox.com/map-styles/standard/guides/)
    final bool enable3D = (mode == MapViewMode.mode3D);

    // Not: Satellite style’da bu config her zaman uygulanmayabilir,
    // o yüzden sadece Standard’da deneyelim.
    if (styleUri == MapboxConfig.styleStandard) {
      await _map!.style.setStyleImportConfigProperties(
        "basemap",
        <String, Object>{
          "show3dObjects": enable3D,
          // İstersen ekstra:
          // "lightPreset": "day",
          // "showPlaceLabels": true,
        },
      );
    }

    // 3) Kamera uygula
    final CameraOptions camera =
    enable3D ? MapboxConfig.camera3D : MapboxConfig.camera2D;

    await _map!.easeTo(
      camera,
      MapAnimationOptions(duration: 450, startDelay: 0),
    );
  }

  Future<void> _recenter(MapViewMode mode) async {
    if (_map == null) return;

    final CameraOptions camera =
    (mode == MapViewMode.mode3D) ? MapboxConfig.camera3D : MapboxConfig.camera2D;

    await _map!.easeTo(
      camera,
      MapAnimationOptions(duration: 550, startDelay: 0),
    );
  }
}