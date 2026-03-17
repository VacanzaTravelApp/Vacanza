import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:mobile/features/checkin/data/services/location_service.dart';
import 'package:mobile/features/poi_search/data/api/poi_search_api_client.dart';
import 'package:mobile/features/poi_search/data/repositories/poi_search_repository_impl.dart';

import '../../application/ar_poi_layout.dart';
import '../../data/ar_poi_source_from_poi_search.dart';
import '../../domain/models/ar_poi.dart';
import '../../domain/services/ar_poi_source.dart';
import '../widgets/ar_poi_chip.dart';

class ArExplorePage extends StatefulWidget {
  const ArExplorePage({super.key});

  @override
  State<ArExplorePage> createState() => _ArExplorePageState();
}

enum _ArModeStatus {
  checking,
  cameraDenied,
  ready,
}

class _ArExplorePageState extends State<ArExplorePage> {
  CameraController? _cameraController;

  _ArModeStatus _status = _ArModeStatus.checking;

  double _deviceHeadingDeg = 0;

  final LocationService _locationService = LocationService();

  List<ArPoi> _pois = const [];
  bool _isLoadingPois = false;
  String? _poisError;

  @override
  void initState() {
    super.initState();
    _checkSupportAndPermissions();
  }

  Future<void> _checkSupportAndPermissions() async {
    final camStatus = await Permission.camera.request();
    if (!camStatus.isGranted) {
      setState(() => _status = _ArModeStatus.cameraDenied);
      return;
    }

    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _status = _ArModeStatus.ready;
      });

      await _loadPoisForCurrentLocation();
    } catch (_) {
      setState(() => _status = _ArModeStatus.cameraDenied);
    }
  }

  Future<void> _loadPoisForCurrentLocation() async {
    setState(() {
      _isLoadingPois = true;
      _poisError = null;
    });

    try {
      final perm = await _locationService.checkAndRequestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() {
          _pois = const [];
          _poisError =
              'Location permission is required to show nearby places in AR.';
        });
        return;
      }

      final pos = await _locationService.getCurrentPosition();

      final apiClient = context.read<PoiSearchApiClient>();
      final poiRepo = PoiSearchRepositoryImpl(apiClient);
      final ArPoiSource source = ArPoiSourceFromPoiSearch(poiRepo);

      final pois = await source.getNearbyArPois(
        lat: pos.latitude,
        lng: pos.longitude,
        categories: null, // MOB-3: all categories; filtering comes later
        radiusMeters: 600,
      );

      if (!mounted) return;

      setState(() {
        _pois = pois;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pois = const [];
        _poisError = 'Could not load nearby places for AR.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingPois = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore in AR'),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _ArModeStatus.checking:
        return const _ArStatusMessage(
          icon: Icons.hourglass_empty_rounded,
          title: 'Preparing AR Mode…',
          message: 'Checking device support and camera permission.',
        );
      case _ArModeStatus.cameraDenied:
        return const _ArStatusMessage(
          icon: Icons.camera_alt_outlined,
          title: 'Camera Permission Required',
          message:
              'Camera access is required to use AR Mode. Please enable it in system settings.',
        );
      case _ArModeStatus.ready:
        final positioned = layoutArPois(
          pois: _pois,
          deviceHeadingDeg: _deviceHeadingDeg,
        );

        return Stack(
          children: [
            Positioned.fill(
              child: _cameraController != null &&
                      _cameraController!.value.isInitialized
                  ? CameraPreview(_cameraController!)
                  : const ColoredBox(color: Colors.black),
            ),
            const _CenterReticle(),
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  children: [
                    if (_isLoadingPois)
                      const Align(
                        alignment: Alignment(0, -0.9),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    if (!_isLoadingPois && _pois.isEmpty && _poisError == null)
                      const Align(
                        alignment: Alignment(0, -0.8),
                        child: Text(
                          'No places found around you for AR.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (_poisError != null)
                      Align(
                        alignment: const Alignment(0, -0.8),
                        child: Text(
                          _poisError!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    for (final p in positioned)
                      Align(
                        alignment: Alignment(
                          p.xFraction * 2 - 1,
                          -0.6 + p.row * 0.25,
                        ),
                        child: ArPoiChip(poi: p.poi),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _CenterReticle extends StatelessWidget {
  const _CenterReticle();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 2,
            ),
            color: Colors.black.withValues(alpha: 0.15),
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArStatusMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _ArStatusMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.grey.shade700),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

