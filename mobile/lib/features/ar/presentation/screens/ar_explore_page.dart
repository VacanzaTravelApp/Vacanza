import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:mobile/features/checkin/data/services/location_service.dart';
import 'package:mobile/features/checkin/presentation/bloc/checkin_bloc.dart';
import 'package:mobile/features/checkin/presentation/bloc/checkin_event.dart';
import 'package:mobile/features/checkin/presentation/bloc/checkin_state.dart';
import 'package:mobile/features/poi_search/data/api/poi_search_api_client.dart';
import 'package:mobile/features/poi_search/data/repositories/poi_search_repository_impl.dart';
import 'package:mobile/features/poi_search/data/models/poi_categories.dart';

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

enum _ArModeStatus { checking, cameraDenied, ready }

class _ArExplorePageState extends State<ArExplorePage> {
  CameraController? _cameraController;

  _ArModeStatus _status = _ArModeStatus.checking;

  double _deviceHeadingDeg = 0;
  ArPoi? _selectedPoi;
  bool _checkinLoading = false;
  String? _checkinMessage;

  final LocationService _locationService = LocationService();

  List<ArPoi> _pois = const [];
  bool _isLoadingPois = false;
  String? _poisError;

  final Set<String> _selectedCategories = Set<String>.from(PoiCategories.defaults);
  bool _showHelp = true;

  int _maxPoisPerCategory = 1;

  StreamSubscription<Position>? _headingSubscription;

  @override
  void initState() {
    super.initState();
    _checkSupportAndPermissions();
    _startHeadingUpdates();
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

      final controller = CameraController(backCamera, ResolutionPreset.medium, enableAudio: false);

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
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        setState(() {
          _pois = const [];
          _poisError = 'Location permission is required to show nearby places in AR.';
        });
        return;
      }

      final pos = await _locationService.getCurrentPosition();

      final apiClient = context.read<PoiSearchApiClient>();
      final poiRepo = PoiSearchRepositoryImpl(apiClient);
      final ArPoiSource source = ArPoiSourceFromPoiSearch(poiRepo);

      final List<String>? effectiveCategories =
          _selectedCategories.isEmpty
              ? null
              : _selectedCategories.map((c) => c.toLowerCase()).toList();

      final pois = await source.getNearbyArPois(
        lat: pos.latitude,
        lng: pos.longitude,
        categories: effectiveCategories,
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

  void _startHeadingUpdates() {
    _headingSubscription?.cancel();
    _headingSubscription = _locationService.positionStream(distanceFilter: 0).listen(
      (Position position) {
        if (!mounted) return;
        final heading = position.heading;
        if (heading >= 0 && heading <= 360) {
          setState(() => _deviceHeadingDeg = heading);
        }
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _headingSubscription?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckinBloc, CheckinState>(
      listenWhen: (prev, next) => prev.status != next.status,
      listener: (context, state) {
        if (state.status == CheckinStatus.loading) {
          setState(() {
            _checkinLoading = true;
            _checkinMessage = null;
          });
        } else if (state.status == CheckinStatus.newCreated) {
          final poiName = state.response?.poiName;
          setState(() {
            _checkinLoading = false;
            _checkinMessage =
                poiName != null ? 'Checked in at $poiName' : 'Checked in!';
          });
        } else if (state.status == CheckinStatus.duplicate) {
          setState(() {
            _checkinLoading = false;
            _checkinMessage = state.response?.message ??
                'You have already checked in here.';
          });
        } else if (state.status == CheckinStatus.noMatch) {
          setState(() {
            _checkinLoading = false;
            _checkinMessage = state.response?.message ??
                'You are too far from this place to check in.';
          });
        } else if (state.status == CheckinStatus.failure) {
          setState(() {
            _checkinLoading = false;
            _checkinMessage = state.errorMessage ??
                'Check-in failed. Please try again.';
          });
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildBody(),
          ),
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
          message: 'Camera access is required to use AR Mode. Please enable it in system settings.',
        );
      case _ArModeStatus.ready:
        final positioned = layoutArPois(
          pois: _pois,
          deviceHeadingDeg: _deviceHeadingDeg,
          maxPerCategory: _maxPoisPerCategory,
        );

        return Stack(
          children: [
            Positioned.fill(
              child:
                  _cameraController != null && _cameraController!.value.isInitialized
                      ? CameraPreview(_cameraController!)
                      : const ColoredBox(color: Colors.black),
            ),
            const _CenterReticle(),
            Positioned.fill(
              child: Stack(
                children: [
                  _buildTopHud(),
                  _buildBottomHud(),
                  for (final p in positioned)
                    Align(
                      alignment: Alignment(p.xFraction * 2 - 1, -0.6 + p.row * 0.25),
                      child: GestureDetector(
                        onTap: () => _onPoiTap(p.poi),
                        child: ArPoiChip(poi: p.poi),
                      ),
                    ),
                ],
              ),
            ),
            if (_showHelp) _buildHelpOverlay(),
            if (_selectedPoi != null) _buildPoiBottomSheet(),
          ],
        );
    }
  }

  void _onPoiTap(ArPoi poi) {
    setState(() {
      _selectedPoi = poi;
    });
  }

  void _closePoiSheet() {
    setState(() {
      _selectedPoi = null;
      _checkinLoading = false;
      _checkinMessage = null;
    });
  }

  Widget _buildPoiBottomSheet() {
    final poi = _selectedPoi!;

    final dist =
        poi.distanceMeters >= 1000
            ? '${(poi.distanceMeters / 1000).toStringAsFixed(1)} km'
            : '${poi.distanceMeters.round()} m';

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          poi.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _closePoiSheet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Approx. $dist away',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  if (_checkinMessage != null) ...[
                    Text(
                      _checkinMessage!,
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _checkinLoading
                              ? null
                              : () async {
                                final poi = _selectedPoi;
                                if (poi == null) return;

                                debugPrint('[AR_CHECKIN] attempt poiId=${poi.id} name=${poi.name}');

                                setState(() {
                                  _checkinLoading = true;
                                  _checkinMessage = null;
                                });

                                final pos = await _locationService.getCurrentPosition();

                                if (!mounted) return;

                                context.read<CheckinBloc>().add(
                                  TriggerAutoCheckin(
                                    latitude: pos.latitude,
                                    longitude: pos.longitude,
                                    candidatePoiIds: [poi.id],
                                  ),
                                );
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Check in here'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHud() {
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Explore in AR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isLoadingPois)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                PopupMenuButton<int>(
                  icon: const Icon(Icons.tune, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    setState(() {
                      _maxPoisPerCategory = value;
                    });
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 1,
                      child: Text('1 per category'),
                    ),
                    PopupMenuItem(
                      value: 2,
                      child: Text('2 per category'),
                    ),
                    PopupMenuItem(
                      value: 3,
                      child: Text('3 per category'),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  onPressed: _loadPoisForCurrentLocation,
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  onPressed: () => setState(() => _showHelp = true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomHud() {
    final chips = PoiCategories.defaults;
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        minimum: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_poisError != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _poisError!,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              )
            else if (!_isLoadingPois && _pois.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'No places found around you for the selected categories.',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Showing ${_pois.length} places',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final key in chips)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(
                            key[0].toUpperCase() + key.substring(1),
                            style: const TextStyle(fontSize: 11),
                          ),
                          selected: _selectedCategories.contains(key),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(key);
                              } else {
                                _selectedCategories.remove(key);
                              }
                            });
                            _loadPoisForCurrentLocation();
                          },
                          backgroundColor: Colors.black.withOpacity(0.3),
                          selectedColor: Colors.white.withOpacity(0.9),
                          checkmarkColor: Colors.black87,
                          labelStyle: TextStyle(
                            color:
                                _selectedCategories.contains(key) ? Colors.black87 : Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.45),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How to use AR Mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Move your phone around to see nearby places overlaid on the camera.\n'
                    '• Use the category buttons at the bottom to filter what you see.\n'
                    '• Tap the refresh icon to reload nearby places.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => _showHelp = false),
                      child: const Text('Got it', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
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

  const _ArStatusMessage({required this.icon, required this.title, required this.message});

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
