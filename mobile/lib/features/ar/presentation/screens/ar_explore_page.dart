import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:ar_flutter_plugin_engine/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_engine/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_engine/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_engine/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_engine/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_engine/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_engine/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_engine/models/ar_node.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/behavior/domain/feedback_poi_ref.dart';
import 'package:mobile/features/behavior/presentation/cubit/favorite_poi_cubit.dart';
import 'package:mobile/features/behavior/presentation/widgets/poi_favorite_heart_button.dart';
import 'package:mobile/features/checkin/data/services/location_service.dart';
import 'package:mobile/features/checkin/presentation/bloc/checkin_bloc.dart';
import 'package:mobile/features/checkin/presentation/bloc/checkin_event.dart';
import 'package:mobile/features/checkin/presentation/bloc/checkin_state.dart';
import 'package:mobile/features/poi_search/data/api/poi_search_api_client.dart';
import 'package:mobile/features/poi_search/data/models/poi_categories.dart';
import 'package:mobile/features/poi_search/data/models/poi_category_catalog.dart';
import 'package:mobile/features/poi_search/data/repositories/poi_search_repository_impl.dart';
import 'package:mobile/features/poi_search/data/utils/poi_client_category_filter.dart';

import '../../application/ar_poi_layout.dart';
import '../../application/ar_world_transform.dart';
import '../../data/ar_hybrid_poi_loader.dart';
import '../../data/ar_nearby_poi_api_client.dart';
import '../../data/ar_poi_source_from_poi_search.dart';
import '../../data/device_heading_service.dart';
import '../../domain/models/ar_poi.dart';
import '../../domain/services/ar_poi_source.dart';
import '../utils/ar_distance_format.dart';
import '../widgets/ar_behind_poi_strip.dart';
import '../widgets/ar_category_filter_sheet.dart';
import '../widgets/ar_poi_chip.dart';

class ArExplorePage extends StatefulWidget {
  const ArExplorePage({super.key});

  @override
  State<ArExplorePage> createState() => _ArExplorePageState();
}

enum _ArModeStatus { checking, cameraDenied, ready }

enum _TopHudAction {
  maxPerCategory1,
  maxPerCategory2,
  maxPerCategory3,
  refreshPois,
  toggleDebugPanel,
  togglePlacementMode,
}

class _ArExplorePageState extends State<ArExplorePage>
    with WidgetsBindingObserver {
  static const String _poiNodeUri =
      'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/master/2.0/Box/glTF-Binary/Box.glb';

  CameraController? _cameraController;
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;

  _ArModeStatus _status = _ArModeStatus.checking;

  double _deviceHeadingDeg = 0;
  ArPoi? _selectedPoi;
  bool _checkinLoading = false;
  String? _checkinMessage;

  final LocationService _locationService = LocationService();
  final DeviceHeadingService _headingService = const DeviceHeadingService();

  List<ArPoi> _pois = const [];
  bool _isLoadingPois = false;
  String? _poisError;

  final Set<String> _selectedCategories = Set<String>.from(
    PoiCategories.defaults,
  );
  bool _showDebugPanel = false;
  double _headingOffsetDeg = 0;
  bool _useWorldAnchors = true;
  bool _isArViewReady = false;
  bool _isSyncingArNodes = false;
  String? _arMessage;

  int _maxPoisPerCategory = 1;

  StreamSubscription<double>? _headingSubscription;
  final List<ARNode> _arNodes = <ARNode>[];
  final Map<String, ArPoi> _poiByNodeName = <String, ArPoi>{};

  double? _lastLocationAccuracyMeters;
  final List<String> _recentPoiIds = <String>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSupportAndPermissions();
    _startHeadingUpdates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FavoritePoiCubit>().refreshAffinity();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _headingSubscription?.cancel();
      _headingSubscription = null;
    } else if (state == AppLifecycleState.resumed) {
      if (_status == _ArModeStatus.ready && _headingSubscription == null) {
        _startHeadingUpdates();
      }
    }
  }

  Future<void> _checkSupportAndPermissions() async {
    debugPrint('[AR_MODE] init: requesting camera permission');

    final camStatus = await Permission.camera.request();
    if (!camStatus.isGranted) {
      debugPrint('[AR_MODE] camera permission denied: $camStatus');
      setState(() => _status = _ArModeStatus.cameraDenied);
      return;
    }

    if (!mounted) return;
    setState(() {
      _status = _ArModeStatus.ready;
    });
    await _loadPoisForCurrentLocation();
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

      if (!mounted) return;
      final apiClient = context.read<PoiSearchApiClient>();
      final dio = context.read<Dio>();
      final poiRepo = PoiSearchRepositoryImpl(apiClient);
      final ArPoiSource fallbackSource = ArPoiSourceFromPoiSearch(poiRepo);
      final nearbyApiClient = ArNearbyPoiApiClient(dio);

      final pos = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _lastLocationAccuracyMeters = pos.accuracy;
      });

      const radiusMeters = 600.0;
      List<ArPoi> pois;
      try {
        final dtos = await nearbyApiClient.getNearbyPois(
          lat: pos.latitude,
          lng: pos.longitude,
          radiusMeters: radiusMeters,
          categories: null,
          limit: 40,
        );
        // Mapbox [MapWidget] bu ekranda kullanılmıyor: Android/iOS platform view
        // AR kamera / ARCore ile aynı hierarchy'de üstte çizilip siyah ekrana yol açıyor.
        // Stil katmanı POI’ları yok; backend [PoiSearchService] + ingest yeterli.
        if (!mounted) return;
        pois = await ArHybridPoiLoader.mergeNearbyAndStylePois(
          lat: pos.latitude,
          lng: pos.longitude,
          radiusMeters: radiusMeters,
          nearbyDtos: dtos,
          mapProbe: null,
        );
      } catch (e, st) {
        debugPrint('[AR_MODE] hybrid POI load failed, fallback: $e\n$st');
        if (!mounted) return;
        pois = await fallbackSource.getNearbyArPois(
          lat: pos.latitude,
          lng: pos.longitude,
          categories: null,
          radiusMeters: radiusMeters,
        );
      }

      final filteredPois = _applyPoiFilters(pois);

      if (!mounted) return;

      setState(() {
        _pois = filteredPois;
      });
      await _syncArNodes();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pois = const [];
        _poisError = 'Could not load nearby places for AR.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPois = false;
        });
      }
    }
  }

  void _startHeadingUpdates() {
    _headingSubscription?.cancel();
    _headingSubscription = _headingService.headingStream().listen((
      double heading,
    ) {
      if (!mounted) return;
      setState(() => _deviceHeadingDeg = heading);
    }, onError: (_) {});
  }

  void _onArViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager _,
    ARLocationManager __,
  ) {
    _disposeFallbackCamera();
    _arSessionManager = arSessionManager;
    _arObjectManager = arObjectManager;

    _arSessionManager!.onInitialize(
      showAnimatedGuide: false,
      showFeaturePoints: false,
      showPlanes: false,
      showWorldOrigin: false,
      handleTaps: false,
    );
    _arObjectManager!.onInitialize();
    _arObjectManager!.onNodeTap = _onArNodeTap;

    if (!mounted) return;
    setState(() {
      _isArViewReady = true;
      _arMessage = null;
    });

    _syncArNodes();
  }

  void _clearArNodes() {
    final manager = _arObjectManager;
    if (manager == null) return;
    for (final node in _arNodes) {
      manager.removeNode(node);
    }
    _arNodes.clear();
    _poiByNodeName.clear();
  }

  Future<void> _ensureFallbackCameraInitialized() async {
    if (_cameraController?.value.isInitialized == true) return;
    try {
      debugPrint('[AR_MODE] initializing fallback camera (CameraX)');
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
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
      });
    } catch (e) {
      debugPrint('[AR_MODE] fallback camera initialization failed: $e');
    }
  }

  void _disposeFallbackCamera() {
    final controller = _cameraController;
    _cameraController = null;
    controller?.dispose();
  }

  Future<void> _syncArNodes() async {
    if (!_useWorldAnchors || !_isArViewReady || _isSyncingArNodes) return;
    final manager = _arObjectManager;
    if (manager == null) return;

    _isSyncingArNodes = true;
    final effectiveHeadingDeg = _normalizeHeadingDeg(
      _deviceHeadingDeg + _headingOffsetDeg,
    );
    final placements = buildArWorldPlacements(
      pois: _pois,
      deviceHeadingDeg: effectiveHeadingDeg,
      maxPerCategory: _maxPoisPerCategory,
    );

    try {
      _clearArNodes();
      final addedNodes = <ARNode>[];
      final nodeToPoi = <String, ArPoi>{};

      for (final placement in placements) {
        final nodeName = 'poi_${placement.poi.id}';
        final scaleFactor = (26.0 / placement.renderDistanceMeters).clamp(
          0.07,
          0.18,
        );
        final node = ARNode(
          type: NodeType.webGLB,
          uri: _poiNodeUri,
          name: nodeName,
          position: vmath.Vector3(
            placement.xMeters,
            placement.yMeters,
            placement.zMeters,
          ),
          scale: vmath.Vector3.all(scaleFactor),
        );
        final added = await manager.addNode(node);
        if (added == true) {
          addedNodes.add(node);
          nodeToPoi[nodeName] = placement.poi;
        }
      }

      if (!mounted) return;
      setState(() {
        _arNodes
          ..clear()
          ..addAll(addedNodes);
        _poiByNodeName
          ..clear()
          ..addAll(nodeToPoi);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _arMessage = 'AR anchors could not be synced. Using fallback overlay.';
        _useWorldAnchors = false;
      });
    } finally {
      _isSyncingArNodes = false;
    }
  }

  Future<void> _onArNodeTap(List<dynamic> nodeNames) async {
    if (nodeNames.isEmpty) return;
    final first = nodeNames.first;
    if (first is! String) return;
    final poi = _poiByNodeName[first];
    if (poi == null || !mounted) return;
    HapticFeedback.lightImpact();
    _recordRecentPoi(poi.id);
    setState(() {
      _selectedPoi = poi;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _headingSubscription?.cancel();
    _clearArNodes();
    _arSessionManager?.dispose();
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
            _checkinMessage =
                state.response?.message ?? 'You have already checked in here.';
          });
        } else if (state.status == CheckinStatus.noMatch) {
          setState(() {
            _checkinLoading = false;
            _checkinMessage =
                state.response?.message ??
                'You are too far from this place to check in.';
          });
        } else if (state.status == CheckinStatus.failure) {
          setState(() {
            _checkinLoading = false;
            _checkinMessage =
                state.errorMessage ?? 'Check-in failed. Please try again.';
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
        return _CameraDeniedMessage(
          onBackToMap: () => Navigator.of(context).pop(),
        );
      case _ArModeStatus.ready:
        return _buildReadyArContent();
    }
  }

  Widget _buildReadyArContent() {
    final effectiveHeadingDeg = _normalizeHeadingDeg(
      _deviceHeadingDeg + _headingOffsetDeg,
    );
    final behindPois = _behindPoisForHeading(effectiveHeadingDeg);
    final frontPois = _frontPoisForHeading(effectiveHeadingDeg);

    final worldPlacements = buildArWorldPlacements(
      pois: _pois,
      deviceHeadingDeg: effectiveHeadingDeg,
      maxPerCategory: _maxPoisPerCategory,
    );
    final positioned = layoutArPois(
      pois: frontPois,
      deviceHeadingDeg: effectiveHeadingDeg,
      maxPerCategory: _maxPoisPerCategory,
    );

    if (_useWorldAnchors) {
      return Stack(
        children: [
          Positioned.fill(
            child: ARView(
              onARViewCreated: _onArViewCreated,
              planeDetectionConfig: PlaneDetectionConfig.none,
            ),
          ),
          Positioned.fill(
            child: Stack(
              children: [
                _buildTopHud(),
                _buildBottomHud(
                  behindPois: behindPois,
                  headingDeg: effectiveHeadingDeg,
                ),
                if (_showDebugPanel)
                  _buildWorldDebugPanel(
                    placements: worldPlacements,
                    effectiveHeadingDeg: effectiveHeadingDeg,
                  ),
                _buildWorldFloatingLabels(worldPlacements, frontPois),
                if (_arMessage != null) _buildArMessage(),
              ],
            ),
          ),
          if (_selectedPoi != null) _buildPoiBottomSheet(),
        ],
      );
    }

    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      Future.microtask(_ensureFallbackCameraInitialized);
    }

    return Stack(
      children: [
        Positioned.fill(
          child:
              _cameraController != null &&
                      _cameraController!.value.isInitialized
                  ? CameraPreview(_cameraController!)
                  : const ColoredBox(color: Colors.black),
        ),
        Positioned.fill(
          child: Stack(
            children: [
              _buildTopHud(),
              _buildBottomHud(
                behindPois: behindPois,
                headingDeg: effectiveHeadingDeg,
              ),
              if (_showDebugPanel)
                _buildDebugPanel(
                  positioned: positioned,
                  effectiveHeadingDeg: effectiveHeadingDeg,
                ),
              for (final p in positioned)
                Align(
                  alignment: Alignment(
                    p.xFraction * 2 - 1,
                    -0.6 + p.row * 0.25,
                  ),
                  child: GestureDetector(
                    onTap: () => _onPoiTap(p.poi),
                    child: ArPoiChip(
                      poi: p.poi,
                      scale: _distanceScaleForPoi(p.poi, frontPois),
                      isSelected: _selectedPoi?.id == p.poi.id,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_selectedPoi != null) _buildPoiBottomSheet(),
      ],
    );
  }

  List<ArPoi> _behindPoisForHeading(double headingDeg) {
    if (_pois.isEmpty) return const [];
    final out = <ArPoi>[];
    for (final p in _pois) {
      final rel = signedRelativeAngleDeg(
        toBearingDeg: p.bearingDegrees,
        fromHeadingDeg: headingDeg,
      );
      if (rel.abs() > 90) out.add(p);
    }
    out.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return out;
  }

  List<ArPoi> _frontPoisForHeading(double headingDeg) {
    if (_pois.isEmpty) return const [];
    final out = <ArPoi>[];
    for (final p in _pois) {
      final rel = signedRelativeAngleDeg(
        toBearingDeg: p.bearingDegrees,
        fromHeadingDeg: headingDeg,
      );
      if (rel.abs() <= 90) out.add(p);
    }
    return out;
  }

  double _distanceScaleForPoi(ArPoi poi, List<ArPoi> cohort) {
    if (cohort.length <= 1) return 1.0;
    final ds = cohort.map((e) => e.distanceMeters).toList();
    final minD = ds.reduce(math.min);
    final maxD = ds.reduce(math.max);
    if ((maxD - minD).abs() < 1.0) return 0.92;
    final t = ((poi.distanceMeters - minD) / (maxD - minD)).clamp(0.0, 1.0);
    return (1.0 - (0.42 * t)).clamp(0.55, 1.0);
  }

  void _onPoiTap(ArPoi poi) {
    HapticFeedback.lightImpact();
    _recordRecentPoi(poi.id);
    setState(() {
      _selectedPoi = poi;
    });
  }

  void _recordRecentPoi(String poiId) {
    _recentPoiIds.remove(poiId);
    _recentPoiIds.insert(0, poiId);
    while (_recentPoiIds.length > 8) {
      _recentPoiIds.removeLast();
    }
  }

  List<ArPoi> _recentPoisOtherThan(String currentId) {
    final byId = {for (final p in _pois) p.id: p};
    final out = <ArPoi>[];
    for (final id in _recentPoiIds) {
      if (id == currentId) continue;
      final p = byId[id];
      if (p != null) {
        out.add(p);
      }
      if (out.length >= 6) break;
    }
    return out;
  }

  Map<String, int> _categoryCountsForFilter() {
    final keys = PoiCategoryCatalog.all.map((e) => e.key);
    final m = {for (final k in keys) k: 0};
    for (final p in _pois) {
      final d = PoiCategoryCatalog.poiCategoryForRaw(p.categoryKey);
      if (d != null) {
        m[d.key] = (m[d.key] ?? 0) + 1;
      }
    }
    return m;
  }

  Future<void> _openCategoryFilter() async {
    await showArCategoryFilterSheet(
      context: context,
      initialSelection: Set<String>.from(_selectedCategories),
      countsByCategory: _categoryCountsForFilter(),
      onSelectionChanged: (next) {
        setState(() {
          _selectedCategories
            ..clear()
            ..addAll(next);
        });
        _loadPoisForCurrentLocation();
      },
    );
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
    final useImperial = localeUsesImperial(context);
    final dist = formatArDistanceMeters(
      poi.distanceMeters,
      useImperial: useImperial,
    );
    final recents = _recentPoisOtherThan(poi.id);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Material(
            color: Colors.black.withValues(alpha: 0.85),
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
                      PoiFavoriteHeartButton(
                        ref: FeedbackPoiRef.fromArPoi(poi),
                        iconSize: 24,
                        padding: EdgeInsets.zero,
                        filledColor: const Color(0xFFFF8A95),
                        outlineColor: Colors.white.withValues(alpha: 0.88),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _closePoiSheet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Yaklaşık $dist uzakta',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 12,
                    ),
                  ),
                  if (recents.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Son bakılanlar',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: recents.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final r = recents[i];
                          return ActionChip(
                            label: Text(
                              r.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _recordRecentPoi(r.id);
                              setState(() => _selectedPoi = r);
                            },
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.14,
                            ),
                            labelStyle: const TextStyle(color: Colors.white),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.28),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (_checkinMessage != null) ...[
                    Text(
                      _checkinMessage!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 12,
                      ),
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

                                debugPrint(
                                  '[AR_CHECKIN] attempt poiId=${poi.id} name=${poi.name}',
                                );

                                setState(() {
                                  _checkinLoading = true;
                                  _checkinMessage = null;
                                });

                                final pos =
                                    await _locationService.getCurrentPosition();

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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Check-in yap'),
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
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: cs.outline.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: cs.onSurface,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    'Explore in AR',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.35,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isLoadingPois)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    ),
                  ),
                PopupMenuButton<_TopHudAction>(
                  tooltip: 'AR options',
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: cs.onSurface,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onSelected: (action) {
                    switch (action) {
                      case _TopHudAction.maxPerCategory1:
                        setState(() => _maxPoisPerCategory = 1);
                        _syncArNodes();
                        break;
                      case _TopHudAction.maxPerCategory2:
                        setState(() => _maxPoisPerCategory = 2);
                        _syncArNodes();
                        break;
                      case _TopHudAction.maxPerCategory3:
                        setState(() => _maxPoisPerCategory = 3);
                        _syncArNodes();
                        break;
                      case _TopHudAction.refreshPois:
                        _loadPoisForCurrentLocation();
                        break;
                      case _TopHudAction.toggleDebugPanel:
                        setState(() => _showDebugPanel = !_showDebugPanel);
                        break;
                      case _TopHudAction.togglePlacementMode:
                        setState(() {
                          _useWorldAnchors = !_useWorldAnchors;
                          _arMessage =
                              _useWorldAnchors
                                  ? 'World-anchor mode enabled.'
                                  : 'Compass fallback mode enabled.';
                        });
                        if (_useWorldAnchors) {
                          _disposeFallbackCamera();
                          _syncArNodes();
                        } else {
                          _clearArNodes();
                          _ensureFallbackCameraInitialized();
                        }
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem<_TopHudAction>(
                          value: _TopHudAction.maxPerCategory1,
                          child: Text(
                            _maxPoisPerCategory == 1
                                ? '✓ 1 per category'
                                : '1 per category',
                          ),
                        ),
                        PopupMenuItem<_TopHudAction>(
                          value: _TopHudAction.maxPerCategory2,
                          child: Text(
                            _maxPoisPerCategory == 2
                                ? '✓ 2 per category'
                                : '2 per category',
                          ),
                        ),
                        PopupMenuItem<_TopHudAction>(
                          value: _TopHudAction.maxPerCategory3,
                          child: Text(
                            _maxPoisPerCategory == 3
                                ? '✓ 3 per category'
                                : '3 per category',
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem<_TopHudAction>(
                          value: _TopHudAction.refreshPois,
                          child: Text('Refresh places'),
                        ),
                        PopupMenuItem<_TopHudAction>(
                          value: _TopHudAction.toggleDebugPanel,
                          child: Text(
                            _showDebugPanel
                                ? 'Hide debug panel'
                                : 'Show debug panel',
                          ),
                        ),
                        PopupMenuItem<_TopHudAction>(
                          value: _TopHudAction.togglePlacementMode,
                          child: Text(
                            _useWorldAnchors
                                ? 'Use compass fallback'
                                : 'Use world anchors',
                          ),
                        ),
                      ],
                ),
              ],
            ),
          ),
        ),
      ),
              if (_lastLocationAccuracyMeters != null &&
                  _lastLocationAccuracyMeters! > 35.0) ...[
                const SizedBox(height: 6),
                Text(
                  'Konum hassasiyeti düşük (±${_lastLocationAccuracyMeters!.round()} m).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.error.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomHud({
    required List<ArPoi> behindPois,
    required double headingDeg,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        minimum: const EdgeInsets.only(bottom: 8, left: 12, right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (behindPois.isNotEmpty)
              ArBehindPoiStrip(
                pois: behindPois,
                deviceHeadingDeg: headingDeg,
                onPoiTap: _onPoiTap,
                selectedPoiId: _selectedPoi?.id,
              ),
            if (_poisError != null) ...[
              if (behindPois.isNotEmpty) const SizedBox(height: 6),
              Text(
                _poisError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (behindPois.isNotEmpty || _poisError != null)
              const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: _isLoadingPois ? null : _openCategoryFilter,
              icon: Icon(Icons.filter_list_rounded, size: 18, color: cs.primary),
              label: Text(
                'Kategoriler · ${_selectedCategories.length}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: cs.onSurface,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                side: BorderSide(
                  color: context.mapControlAccent.withValues(alpha: 0.45),
                ),
                backgroundColor: cs.surface.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorldFloatingLabels(
    List<ArWorldPlacement> placements,
    List<ArPoi> frontCohort,
  ) {
    if (placements.isEmpty) return const SizedBox.shrink();
    final labels = _buildWorldLabelPositions(placements);
    return Align(
      alignment: Alignment.center,
      child: IgnorePointer(
        ignoring: false,
        child: Stack(
          children: [
            for (final label in labels)
              Align(
                alignment: Alignment(label.x * 2 - 1, label.yAlign),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 190),
                  child: GestureDetector(
                    onTap: () => _onPoiTap(label.placement.poi),
                    child: ArPoiChip(
                      poi: label.placement.poi,
                      scale: label.scale *
                          _distanceScaleForPoi(
                            label.placement.poi,
                            frontCohort,
                          ),
                      isSelected: _selectedPoi?.id == label.placement.poi.id,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<_WorldLabelPosition> _buildWorldLabelPositions(
    List<ArWorldPlacement> placements,
  ) {
    final placed = <_WorldLabelPosition>[];
    const visibleFovDeg = 55.0;
    const minXGap = 0.17;
    const maxRows = 4;

    // Keep labels stable and readable by favoring closer POIs first.
    final sorted = [...placements]
      ..sort((a, b) => a.poi.distanceMeters.compareTo(b.poi.distanceMeters));
    final minDistance = sorted.first.poi.distanceMeters;
    final maxDistance = sorted.last.poi.distanceMeters;

    for (final placement in sorted) {
      final rel = placement.relativeBearingDeg;
      var x = (0.5 + (rel / visibleFovDeg) * 0.5).clamp(0.08, 0.92);
      int row = 0;
      while (row < maxRows &&
          placed.any((p) => p.row == row && (p.x - x).abs() < minXGap)) {
        row++;
      }
      if (row >= maxRows) {
        // If crowded, nudge horizontally to nearest free slot.
        x = (x + 0.08).clamp(0.08, 0.92);
        row = maxRows - 1;
      }
      placed.add(
        _WorldLabelPosition(
          placement: placement,
          x: x,
          row: row,
          yAlign: -0.56 + (row * 0.2),
          scale: _relativeLabelScale(
            placement.poi.distanceMeters,
            minDistance,
            maxDistance,
          ),
        ),
      );
    }
    return placed;
  }

  double _relativeLabelScale(
    double distanceMeters,
    double minDistanceMeters,
    double maxDistanceMeters,
  ) {
    if ((maxDistanceMeters - minDistanceMeters).abs() < 0.1) {
      return 0.9;
    }
    final t = ((distanceMeters - minDistanceMeters) /
            (maxDistanceMeters - minDistanceMeters))
        .clamp(0.0, 1.0);
    return (1.0 - (0.38 * t)).clamp(0.58, 1.0);
  }

  bool _isDisplayablePoiName(String rawName) {
    final normalized = rawName.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return normalized != 'unnamed' &&
        normalized != 'null' &&
        normalized != 'undefined' &&
        normalized != '-';
  }

  List<ArPoi> _applyPoiFilters(List<ArPoi> pois) {
    if (_selectedCategories.isEmpty) {
      return const [];
    }

    final clientCats = PoiClientCategoryFilter.categoriesForSearch(
      _selectedCategories.toList(),
    );
    final selectedSet = <String>{
      if (clientCats != null)
        for (final c in clientCats) c.trim().toLowerCase(),
    };

    final out = <ArPoi>[];
    final seenKeys = <String>{};

    for (final poi in pois) {
      if (!_isDisplayablePoiName(poi.name)) continue;

      if (!PoiCategoryCatalog.passesCategoryFilter(
        rawCategory: poi.categoryKey,
        selectedUiKeys: selectedSet,
        treatEmptySelectionAsShowAll: true,
      )) {
        continue;
      }

      final dedupeKey = _buildPoiDedupeKey(poi);
      if (!seenKeys.add(dedupeKey)) continue;
      out.add(poi);
    }

    out.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return out;
  }

  String _buildPoiDedupeKey(ArPoi poi) {
    final id = poi.id.trim().toLowerCase();
    if (id.isNotEmpty) return 'id:$id';
    final name = poi.name.trim().toLowerCase();
    final cat = _canonicalCategory(poi.categoryKey);
    final dist = poi.distanceMeters.round();
    final bearing = poi.bearingDegrees.round();
    return 'fallback:$name|$cat|$dist|$bearing';
  }

  String _canonicalCategory(String raw) {
    final c = raw.trim().toLowerCase();
    switch (c) {
      case 'restaurants':
        return 'restaurant';
      case 'cafes':
        return 'cafe';
      case 'museums':
        return 'museum';
      case 'monument':
        return 'monuments';
      case 'park':
        return 'parks';
      default:
        return c;
    }
  }

  Widget _buildWorldDebugPanel({
    required List<ArWorldPlacement> placements,
    required double effectiveHeadingDeg,
  }) {
    ArWorldPlacement? focus;
    if (_selectedPoi != null) {
      for (final p in placements) {
        if (p.poi.id == _selectedPoi!.id) {
          focus = p;
          break;
        }
      }
    }
    focus ??= placements.isNotEmpty ? placements.first : null;

    final poiName = focus?.poi.name ?? '-';
    final rel = focus?.relativeBearingDeg.toStringAsFixed(1) ?? '-';
    final dist = focus?.poi.distanceMeters.toStringAsFixed(1) ?? '-';
    final arDist = focus?.renderDistanceMeters.toStringAsFixed(1) ?? '-';

    return Align(
      alignment: Alignment.topRight,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 68, right: 12),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 260),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.68),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white, fontSize: 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'AR World Anchor Debug',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'mode: ${_useWorldAnchors ? 'world-anchor' : 'fallback'}',
                  ),
                  Text('arReady: $_isArViewReady'),
                  Text('rawHeading: ${_deviceHeadingDeg.toStringAsFixed(1)}°'),
                  Text('effective: ${effectiveHeadingDeg.toStringAsFixed(1)}°'),
                  Text('anchors: ${_arNodes.length}'),
                  const SizedBox(height: 4),
                  Text('focusPoi: $poiName'),
                  Text('relative: $rel°'),
                  Text('poiDistance: $dist m'),
                  Text('renderDistance: $arDist m'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArMessage() {
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 64),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _arMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDebugPanel({
    required List<ArPoiPositioned> positioned,
    required double effectiveHeadingDeg,
  }) {
    final ArPoiPositioned? focus = _resolveDebugFocus(positioned);
    final String poiName = focus?.poi.name ?? '-';
    final String poiBearing =
        focus != null ? focus.poi.bearingDegrees.toStringAsFixed(1) : '-';
    final String relAngle =
        focus != null
            ? _signedRelativeAngleDeg(
              toBearingDeg: focus.poi.bearingDegrees,
              fromHeadingDeg: effectiveHeadingDeg,
            ).toStringAsFixed(1)
            : '-';
    final String xFraction =
        focus != null ? focus.xFraction.toStringAsFixed(3) : '-';

    return Align(
      alignment: Alignment.topRight,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 68, right: 12),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 250),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.68),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white, fontSize: 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'AR Debug / Calibration',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text('rawHeading: ${_deviceHeadingDeg.toStringAsFixed(1)}°'),
                  Text('offset: ${_headingOffsetDeg.toStringAsFixed(1)}°'),
                  Text('effective: ${effectiveHeadingDeg.toStringAsFixed(1)}°'),
                  const SizedBox(height: 4),
                  Text('focusPoi: $poiName'),
                  Text('poiBearing: $poiBearing°'),
                  Text('relative: $relAngle°'),
                  Text('xFraction: $xFraction'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _headingOffsetDeg = _normalizeSigned180(
                                _headingOffsetDeg - 2,
                              );
                            });
                            _syncArNodes();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            minimumSize: const Size(0, 34),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('-2°'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _headingOffsetDeg = 0;
                            });
                            _syncArNodes();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            minimumSize: const Size(0, 34),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _headingOffsetDeg = _normalizeSigned180(
                                _headingOffsetDeg + 2,
                              );
                            });
                            _syncArNodes();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            minimumSize: const Size(0, 34),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('+2°'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ArPoiPositioned? _resolveDebugFocus(List<ArPoiPositioned> positioned) {
    if (positioned.isEmpty) return null;
    if (_selectedPoi != null) {
      for (final p in positioned) {
        if (p.poi.id == _selectedPoi!.id) return p;
      }
    }
    return positioned.reduce((a, b) {
      final aDist = (a.xFraction - 0.5).abs();
      final bDist = (b.xFraction - 0.5).abs();
      return aDist <= bDist ? a : b;
    });
  }

  double _normalizeHeadingDeg(double deg) {
    final normalized = deg % 360.0;
    return normalized < 0 ? normalized + 360.0 : normalized;
  }

  double _normalizeSigned180(double deg) {
    var normalized = deg % 360.0;
    if (normalized > 180.0) normalized -= 360.0;
    if (normalized < -180.0) normalized += 360.0;
    return normalized;
  }

  double _signedRelativeAngleDeg({
    required double toBearingDeg,
    required double fromHeadingDeg,
  }) {
    return _normalizeSigned180(toBearingDeg - fromHeadingDeg);
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

class _CameraDeniedMessage extends StatelessWidget {
  final VoidCallback onBackToMap;

  const _CameraDeniedMessage({required this.onBackToMap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Camera not available for AR',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Camera access is required to use AR Mode. This device or emulator may not support camera for AR, or the permission was denied.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Geolocator.openAppSettings();
                  },
                  child: const Text('Open app settings'),
                ),
                ElevatedButton(
                  onPressed: onBackToMap,
                  child: const Text('Back to map'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorldLabelPosition {
  final ArWorldPlacement placement;
  final double x;
  final int row;
  final double yAlign;
  final double scale;

  const _WorldLabelPosition({
    required this.placement,
    required this.x,
    required this.row,
    required this.yAlign,
    required this.scale,
  });
}
