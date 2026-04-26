import 'dart:async';
import 'dart:math' as math;

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
import 'package:mobile/core/widgets/vacanza_gradient_button.dart';
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
import 'package:mobile/features/poi_search/presentation/bloc/poi_search_bloc.dart';

import '../../data/poi_to_ar_poi.dart';

import '../../application/ar_poi_layout.dart';
import '../../application/ar_world_transform.dart';
import '../../data/ar_hybrid_poi_loader.dart';
import '../../data/ar_nearby_poi_api_client.dart';
import '../../data/ar_poi_source_from_poi_search.dart';
import '../../data/device_heading_service.dart';
import '../../domain/models/ar_poi.dart';
import '../../domain/services/ar_poi_source.dart';
import '../styles/ar_poi_style.dart';
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

  final LocationService _locationService = LocationService();
  final DeviceHeadingService _headingService = const DeviceHeadingService();

  List<ArPoi> _pois = const [];
  bool _isLoadingPois = false;
  String? _poisError;

  final Set<String> _selectedCategories = Set<String>.from(
    PoiCategories.defaults,
  );

  bool _useWorldAnchors = true;
  bool _isArViewReady = false;
  bool _isSyncingArNodes = false;

  StreamSubscription<double>? _headingSubscription;
  final List<ARNode> _arNodes = <ARNode>[];
  final Map<String, ArPoi> _poiByNodeName = <String, ArPoi>{};
  final List<String> _recentPoiIds = <String>[];

  // Auto check-in
  Position? _lastPosition;
  String? _checkinToastMessage;
  Color? _checkinToastColor;
  Timer? _checkinToastTimer;

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
    final camStatus = await Permission.camera.request();
    if (!camStatus.isGranted) {
      setState(() => _status = _ArModeStatus.cameraDenied);
      return;
    }
    if (!mounted) return;
    setState(() => _status = _ArModeStatus.ready);
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
          _poisError = 'Location permission is required to show nearby places.';
        });
        return;
      }

      if (!mounted) return;
      final pos = await _locationService.getCurrentPosition();
      if (!mounted) return;
      _lastPosition = pos;

      List<ArPoi> pois;

      // Primary: use the map's already-merged (backend + Mapbox) POI list.
      // AR is always opened from the map, so this data is current.
      List<ArPoi>? mapSourcePois;
      try {
        final mapPois = context.read<PoiSearchBloc>().state.pois;
        if (mapPois.isNotEmpty) {
          mapSourcePois = mapPois
              .map((p) => poiToArPoi(p, pos.latitude, pos.longitude))
              .toList(growable: false)
            ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
        }
      } catch (_) {
        // PoiSearchBloc not in scope — fall through to network fetch
      }

      if (mapSourcePois != null) {
        pois = mapSourcePois;
      } else {
        // Fallback: direct network fetch (bloc not available).
        final apiClient = context.read<PoiSearchApiClient>();
        final dio = context.read<Dio>();
        final poiRepo = PoiSearchRepositoryImpl(apiClient);
        final ArPoiSource fallbackSource = ArPoiSourceFromPoiSearch(poiRepo);
        final nearbyApiClient = ArNearbyPoiApiClient(dio);
        const radiusMeters = 600.0;
        try {
          final dtos = await nearbyApiClient.getNearbyPois(
            lat: pos.latitude,
            lng: pos.longitude,
            radiusMeters: radiusMeters,
            categories: null,
            limit: 40,
          );
          if (!mounted) return;
          pois = await ArHybridPoiLoader.mergeNearbyAndStylePois(
            lat: pos.latitude,
            lng: pos.longitude,
            radiusMeters: radiusMeters,
            nearbyDtos: dtos,
            mapProbe: null,
          );
        } catch (_) {
          if (!mounted) return;
          pois = await fallbackSource.getNearbyArPois(
            lat: pos.latitude,
            lng: pos.longitude,
            categories: null,
            radiusMeters: radiusMeters,
          );
        }
      }

      final filteredPois = _applyPoiFilters(pois);
      if (!mounted) return;
      setState(() => _pois = filteredPois);

      _triggerAutoCheckin(pos);
      await _syncArNodes();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pois = const [];
        _poisError = 'Could not load nearby places.';
      });
    } finally {
      if (mounted) setState(() => _isLoadingPois = false);
    }
  }

  void _triggerAutoCheckin(Position pos) {
    final nearbyIds = _pois
        .where((p) => p.distanceMeters < 150)
        .map((p) => p.id)
        .toList();
    if (nearbyIds.isEmpty || !mounted) return;
    context.read<CheckinBloc>().add(TriggerAutoCheckin(
      latitude: pos.latitude,
      longitude: pos.longitude,
      candidatePoiIds: nearbyIds,
    ));
  }

  void _triggerAutoCheckinForPoi(ArPoi poi) {
    final pos = _lastPosition;
    if (pos == null || !mounted) return;
    context.read<CheckinBloc>().add(TriggerAutoCheckin(
      latitude: pos.latitude,
      longitude: pos.longitude,
      candidatePoiIds: [poi.id],
    ));
  }

  void _showCheckinToast(String message) {
    _checkinToastTimer?.cancel();
    setState(() {
      _checkinToastMessage = message;
      _checkinToastColor = const Color(0xFF4ADE80);
    });
    _checkinToastTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _checkinToastMessage = null);
    });
  }

  void _startHeadingUpdates() {
    _headingSubscription?.cancel();
    _headingSubscription = _headingService.headingStream().listen(
      (double heading) {
        if (!mounted) return;
        setState(() => _deviceHeadingDeg = heading);
      },
      onError: (_) {},
    );
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
    setState(() => _isArViewReady = true);
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
      setState(() => _cameraController = controller);
    } catch (_) {}
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
    final placements = buildArWorldPlacements(
      pois: _pois,
      deviceHeadingDeg: _deviceHeadingDeg,
      maxPerCategory: 2,
    );

    try {
      _clearArNodes();
      final addedNodes = <ARNode>[];
      final nodeToPoi = <String, ArPoi>{};

      for (final placement in placements) {
        final nodeName = 'poi_${placement.poi.id}';
        final scaleFactor =
            (26.0 / placement.renderDistanceMeters).clamp(0.07, 0.18);
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
      setState(() => _useWorldAnchors = false);
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
    _onPoiTap(poi);
  }

  void _onPoiTap(ArPoi poi) {
    HapticFeedback.lightImpact();
    _recordRecentPoi(poi.id);
    setState(() => _selectedPoi = poi);
    _triggerAutoCheckinForPoi(poi);
  }

  void _closePoiSheet() {
    setState(() => _selectedPoi = null);
  }

  @override
  void dispose() {
    _checkinToastTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _headingSubscription?.cancel();
    _clearArNodes();
    _arSessionManager?.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<CheckinBloc, CheckinState>(
      listenWhen: (prev, next) => prev.status != next.status,
      listener: (context, state) {
        if (state.status == CheckinStatus.newCreated) {
          final name = state.response?.poiName ?? 'this place';
          _showCheckinToast('Checked in at $name!');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _ArModeStatus.checking:
        return const _ArLoadingScreen(
          message: 'Scanning surroundings…',
        );
      case _ArModeStatus.cameraDenied:
        return _CameraDeniedScreen(
          onBack: () => Navigator.of(context).pop(),
        );
      case _ArModeStatus.ready:
        return _buildReadyArContent();
    }
  }

  Widget _buildReadyArContent() {
    final headingDeg = _deviceHeadingDeg;
    final behindPois = _behindPoisForHeading(headingDeg);
    final frontPois = _frontPoisForHeading(headingDeg);

    final worldPlacements = buildArWorldPlacements(
      pois: _pois,
      deviceHeadingDeg: headingDeg,
      maxPerCategory: 2,
    );
    final positioned = layoutArPois(
      pois: frontPois,
      deviceHeadingDeg: headingDeg,
      maxPerCategory: 2,
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
                _buildWorldFloatingLabels(worldPlacements, frontPois),
                _buildBottomHud(
                  behindPois: behindPois,
                  headingDeg: headingDeg,
                ),
                if (_checkinToastMessage != null) _buildToastOverlay(),
              ],
            ),
          ),
          if (_selectedPoi != null) _buildPoiBottomSheet(),
        ],
      );
    }

    // Compass fallback
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      Future.microtask(_ensureFallbackCameraInitialized);
    }

    return Stack(
      children: [
        Positioned.fill(
          child: _cameraController != null &&
                  _cameraController!.value.isInitialized
              ? CameraPreview(_cameraController!)
              : const ColoredBox(color: Colors.black),
        ),
        Positioned.fill(
          child: Stack(
            children: [
              _buildTopHud(),
              ...positioned.map((p) {
                final opacity = _xFractionOpacity(p.xFraction);
                return Align(
                  alignment: Alignment(
                    p.xFraction * 2 - 1,
                    -0.6 + p.row * 0.25,
                  ),
                  child: IgnorePointer(
                    ignoring: opacity < 0.05,
                    child: Opacity(
                      opacity: opacity,
                      child: ArPoiChip(
                        poi: p.poi,
                        scale: _distanceScaleForPoi(p.poi, frontPois),
                        isSelected: _selectedPoi?.id == p.poi.id,
                        onTap: () => _onPoiTap(p.poi),
                      ),
                    ),
                  ),
                );
              }),
              _buildBottomHud(
                behindPois: behindPois,
                headingDeg: headingDeg,
              ),
              if (_checkinToastMessage != null) _buildToastOverlay(),
            ],
          ),
        ),
        if (_selectedPoi != null) _buildPoiBottomSheet(),
      ],
    );
  }

  // ── HUD ───────────────────────────────────────────────────────────────────

  Widget _buildTopHud() {
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _ArGlassButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              if (_isLoadingPois) ...[
                const _ArSpinner(),
                const SizedBox(width: 10),
              ],
              _ArGlassButton(
                icon: Icons.tune_rounded,
                onTap: _openCategoryFilter,
                isActive: _selectedCategories.length <
                    PoiCategoryCatalog.all.length,
              ),
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
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        minimum: const EdgeInsets.only(bottom: 4),
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
            if (_poisError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Text(
                  _poisError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xCCFF6B6B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToastOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final toastColor = _checkinToastColor ?? const Color(0xFF4ADE80);
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 64, left: 24, right: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xEE060613) : const Color(0xEEFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: toastColor.withValues(alpha: 0.50),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: toastColor.withValues(alpha: 0.28),
                  blurRadius: 18,
                ),
                BoxShadow(
                  color: isDark
                      ? const Color(0x66000000)
                      : const Color(0x22000000),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: toastColor, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _checkinToastMessage!,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF111827),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── POI Detail Sheet ───────────────────────────────────────────────────────

  Widget _buildPoiBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final poi = _selectedPoi!;
    final glowColor = arPoiRingColorForCategory(poi.categoryKey);
    final icon = arPoiIconForCategory(poi.categoryKey);
    final categoryLabel = PoiCategoryCatalog.labelForRawCategory(
          poi.categoryKey,
        ) ??
        poi.categoryKey;
    final dist = formatArDistanceMeters(
      poi.distanceMeters,
      useImperial: localeUsesImperial(context),
    );
    final recents = _recentPoisOtherThan(poi.id);

    final Color sheetBg =
        isDark ? const Color(0xF0060613) : const Color(0xF5FFFFFF);
    final Color nameColor =
        isDark ? Colors.white : const Color(0xFF111827);
    final Color closeBtnBg = isDark
        ? const Color(0x26FFFFFF)
        : const Color(0xFFF3F4F6);
    final Color closeBtnBorder =
        isDark ? const Color(0x26FFFFFF) : const Color(0xFFE5E7EB);
    final Color closeIconColor =
        isDark ? const Color(0xCCFFFFFF) : const Color(0xFF6B7280);
    final Color sectionLabelColor =
        isDark ? const Color(0x66FFFFFF) : const Color(0xFF9CA3AF);
    final Color recentTextColor =
        isDark ? const Color(0xCCFFFFFF) : const Color(0xFF374151);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: glowColor.withValues(alpha: isDark ? 0.28 : 0.35),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: isDark ? 0.20 : 0.14),
                  blurRadius: 28,
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: isDark
                      ? const Color(0x99000000)
                      : const Color(0x22000000),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Category color accent line
                  Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          glowColor.withValues(alpha: 0.80),
                          glowColor,
                          glowColor.withValues(alpha: 0.80),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category + close row
                        Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: glowColor.withValues(alpha: 0.18),
                                border: Border.all(
                                  color: glowColor.withValues(alpha: 0.45),
                                  width: 0.8,
                                ),
                              ),
                              child: Icon(icon, size: 12, color: glowColor),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              categoryLabel.toUpperCase(),
                              style: TextStyle(
                                color: glowColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _closePoiSheet,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: closeBtnBg,
                                  border: Border.all(
                                    color: closeBtnBorder,
                                    width: 0.8,
                                  ),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 15,
                                  color: closeIconColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // POI name
                        Text(
                          poi.name,
                          style: TextStyle(
                            color: nameColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        // Distance + favorite row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: glowColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: glowColor.withValues(alpha: 0.30),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.place_rounded,
                                    size: 12,
                                    color: glowColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    dist,
                                    style: TextStyle(
                                      color: glowColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            PoiFavoriteHeartButton(
                              ref: FeedbackPoiRef.fromArPoi(poi),
                              iconSize: 22,
                              padding: EdgeInsets.zero,
                              filledColor: const Color(0xFFFF8A95),
                              outlineColor: isDark
                                  ? Colors.white.withValues(alpha: 0.70)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                        // Recent POIs
                        if (recents.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            'RECENTLY VIEWED',
                            style: TextStyle(
                              color: sectionLabelColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 32,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: recents.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 6),
                              itemBuilder: (context, i) {
                                final r = recents[i];
                                final rColor =
                                    arPoiRingColorForCategory(r.categoryKey);
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    _recordRecentPoi(r.id);
                                    setState(() => _selectedPoi = r);
                                    _triggerAutoCheckinForPoi(r);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: rColor.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: rColor.withValues(alpha: 0.28),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      r.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: recentTextColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
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

  // ── World AR floating labels ───────────────────────────────────────────────

  Widget _buildWorldFloatingLabels(
    List<ArWorldPlacement> placements,
    List<ArPoi> frontCohort,
  ) {
    if (placements.isEmpty) return const SizedBox.shrink();
    final labels = _buildWorldLabelPositions(placements);
    return Align(
      alignment: Alignment.center,
      child: Stack(
        children: [
          for (final label in labels)
            Align(
              alignment: Alignment(label.x * 2 - 1, label.yAlign),
              child: IgnorePointer(
                ignoring: label.opacity < 0.05,
                child: Opacity(
                  opacity: label.opacity,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 190),
                    child: ArPoiChip(
                      poi: label.placement.poi,
                      scale: label.scale *
                          _distanceScaleForPoi(
                            label.placement.poi,
                            frontCohort,
                          ),
                      isSelected: _selectedPoi?.id == label.placement.poi.id,
                      onTap: () => _onPoiTap(label.placement.poi),
                    ),
                  ),
                ),
              ),
            ),
        ],
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

    final sorted = [...placements]
      ..sort((a, b) => a.poi.distanceMeters.compareTo(b.poi.distanceMeters));
    final minDistance = sorted.first.poi.distanceMeters;
    final maxDistance = sorted.last.poi.distanceMeters;

    for (final placement in sorted) {
      final rel = placement.relativeBearingDeg;
      final absRel = rel.abs();

      // Compute fade opacity: full at ≤60°, gone at ≥82°
      final opacity = absRel <= 60
          ? 1.0
          : absRel >= 82
              ? 0.0
              : 1.0 - (absRel - 60) / 22.0;

      // Skip completely invisible chips to avoid overlap calculations
      if (opacity <= 0) continue;

      var x = (0.5 + (rel / visibleFovDeg) * 0.5).clamp(0.02, 0.98);
      int row = 0;
      while (row < maxRows &&
          placed.any((p) => p.row == row && (p.x - x).abs() < minXGap)) {
        row++;
      }
      if (row >= maxRows) {
        x = (x + 0.08).clamp(0.02, 0.98);
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
          opacity: opacity,
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
    if ((maxDistanceMeters - minDistanceMeters).abs() < 0.1) return 0.9;
    final t = ((distanceMeters - minDistanceMeters) /
            (maxDistanceMeters - minDistanceMeters))
        .clamp(0.0, 1.0);
    return (1.0 - (0.38 * t)).clamp(0.58, 1.0);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  // Fades compass-fallback chips: full opacity in center, gone near edges.
  // xFraction 0..1 maps rel bearing -90°..+90° via layoutArPois.
  double _xFractionOpacity(double xFraction) {
    final d = (xFraction - 0.5).abs(); // 0 = center, 0.5 = edge
    if (d <= 0.333) return 1.0; // within ±60°
    if (d >= 0.456) return 0.0; // beyond ±82°
    return 1.0 - (d - 0.333) / (0.456 - 0.333);
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
      if (p != null) out.add(p);
      if (out.length >= 6) break;
    }
    return out;
  }

  Future<void> _openCategoryFilter() async {
    await showArCategoryFilterSheet(
      context: context,
      initialSelection: Set<String>.from(_selectedCategories),
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

  bool _isDisplayablePoiName(String rawName) {
    final n = rawName.trim().toLowerCase();
    if (n.isEmpty) return false;
    return n != 'unnamed' && n != 'null' && n != 'undefined' && n != '-';
  }

  List<ArPoi> _applyPoiFilters(List<ArPoi> pois) {
    if (_selectedCategories.isEmpty) return const [];

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

}

// ── Loading Screen ─────────────────────────────────────────────────────────

class _ArLoadingScreen extends StatelessWidget {
  final String message;

  const _ArLoadingScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PulsingOrb(),
            const SizedBox(height: 28),
            Text(
              message,
              style: const TextStyle(
                color: Color(0x80FFFFFF),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Camera Denied Screen ───────────────────────────────────────────────────

class _CameraDeniedScreen extends StatelessWidget {
  final VoidCallback onBack;

  const _CameraDeniedScreen({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x1AFF6B6B),
                  border: Border.all(
                    color: const Color(0x66FF6B6B),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33FF6B6B),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.no_photography_rounded,
                  size: 32,
                  color: Color(0xCCFF6B6B),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Camera Access Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'AR mode needs camera permission to place points of interest in your surroundings.',
                style: TextStyle(
                  color: Color(0x80FFFFFF),
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Geolocator.openAppSettings(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0x1AFFFFFF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0x26FFFFFF),
                            width: 0.8,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Open Settings',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: VacanzaGradientButton(
                      label: 'Back to map',
                      onPressed: onBack,
                      enabled: true,
                      minHeight: 46,
                      borderRadius: 14,
                      horizontalPadding: 16,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared private widgets ─────────────────────────────────────────────────

class _ArGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _ArGlassButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.mapControlAccent;

    final Color bg = isDark ? const Color(0xCC060613) : const Color(0xEEFFFFFF);
    final Color idleBorder =
        isDark ? const Color(0x33FFFFFF) : const Color(0x33000000);
    final Color idleIcon =
        isDark ? Colors.white : const Color(0xFF111827);
    final Color shadowColor =
        isDark ? const Color(0x66000000) : const Color(0x22000000);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? accent.withValues(alpha: 0.65) : idleBorder,
            width: 1.0,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: accent.withValues(alpha: 0.30),
                blurRadius: 12,
              ),
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isActive ? accent : idleIcon,
          size: 19,
        ),
      ),
    );
  }
}

class _ArSpinner extends StatelessWidget {
  const _ArSpinner();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 1.8,
        color: isDark
            ? Colors.white.withValues(alpha: 0.6)
            : Colors.black.withValues(alpha: 0.5),
      ),
    );
  }
}

class _PulsingOrb extends StatefulWidget {
  const _PulsingOrb();

  @override
  State<_PulsingOrb> createState() => _PulsingOrbState();
}

class _PulsingOrbState extends State<_PulsingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const orbColor = Color(0xFF818CF8);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer expanding ring
              Opacity(
                opacity: ((1 - t) * 0.35).clamp(0.0, 0.35),
                child: Container(
                  width: 60 + t * 60,
                  height: 60 + t * 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: orbColor,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              // Mid ring
              Opacity(
                opacity: ((1 - t) * 0.55).clamp(0.0, 0.55),
                child: Container(
                  width: 44 + t * 28,
                  height: 44 + t * 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: orbColor,
                      width: 1.0,
                    ),
                  ),
                ),
              ),
              // Core glow
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: orbColor.withValues(alpha: 0.18),
                  border: Border.all(
                    color: orbColor.withValues(alpha: 0.70),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: orbColor.withValues(alpha: 0.55),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  size: 16,
                  color: Color(0xCCFFFFFF),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Label position helper ──────────────────────────────────────────────────

class _WorldLabelPosition {
  final ArWorldPlacement placement;
  final double x;
  final int row;
  final double yAlign;
  final double scale;
  final double opacity;

  const _WorldLabelPosition({
    required this.placement,
    required this.x,
    required this.row,
    required this.yAlign,
    required this.scale,
    required this.opacity,
  });
}
