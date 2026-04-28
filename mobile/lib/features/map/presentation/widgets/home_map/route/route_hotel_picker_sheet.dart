import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import 'package:mobile/core/config/mapbox_config.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/ai/data/api/ai_route_api_client.dart';

class RouteHotelPickerSheet extends StatefulWidget {
  final String routeId;
  final String? defaultDestination;

  /// Initial map viewport — first POI of the route if available.
  final double? initialLat;
  final double? initialLon;

  const RouteHotelPickerSheet({
    super.key,
    required this.routeId,
    this.defaultDestination,
    this.initialLat,
    this.initialLon,
  });

  static Future<void> show(
    BuildContext context, {
    required String routeId,
    String? defaultDestination,
    double? initialLat,
    double? initialLon,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RouteHotelPickerSheet(
        routeId: routeId,
        defaultDestination: defaultDestination,
        initialLat: initialLat,
        initialLon: initialLon,
      ),
    );
  }

  @override
  State<RouteHotelPickerSheet> createState() => _RouteHotelPickerSheetState();
}

class _GeoSuggestion {
  final String placeName;
  final String shortName;
  final double lat;
  final double lon;

  const _GeoSuggestion({
    required this.placeName,
    required this.shortName,
    required this.lat,
    required this.lon,
  });

  static _GeoSuggestion? fromJson(Map<String, dynamic> json) {
    final center = json['center'];
    if (center is! List || center.length < 2) return null;
    return _GeoSuggestion(
      placeName: (json['place_name'] ?? '').toString(),
      shortName: (json['text'] ?? json['place_name'] ?? '').toString(),
      lon: (center[0] as num).toDouble(),
      lat: (center[1] as num).toDouble(),
    );
  }
}

class _RouteHotelPickerSheetState extends State<RouteHotelPickerSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final Dio _geocodeDio;

  bool _saving = false;
  bool _geocoding = false;
  List<_GeoSuggestion> _suggestions = [];
  bool _suggestionsOpen = false;
  Timer? _geocodeTimer;

  mb.MapboxMap? _mapController;
  mb.CircleAnnotationManager? _pinManager;
  mb.CircleAnnotation? _pinAnnotation;
  double? _pinLat;
  double? _pinLon;

  late double _viewportLat;
  late double _viewportLon;
  late double _viewportZoom;

  bool _pinPlaced = false;

  @override
  void initState() {
    super.initState();
    _geocodeDio = Dio();
    _nameCtrl = TextEditingController();
    _addressCtrl = TextEditingController(
      text: widget.defaultDestination ?? '',
    );
    _nameCtrl.addListener(() => setState(() {}));
    _addressCtrl.addListener(_onAddressChanged);

    // First POI coordinates take priority — no geocoding round-trip needed.
    if (widget.initialLat != null && widget.initialLon != null) {
      _viewportLat = widget.initialLat!;
      _viewportLon = widget.initialLon!;
      _viewportZoom = 12.0;
    } else {
      _viewportLat = 48.8566;
      _viewportLon = 2.3522;
      _viewportZoom = 3.5;
      final dest = widget.defaultDestination;
      if (dest != null && dest.isNotEmpty) {
        _geocodeForViewport(dest);
      }
    }
  }

  @override
  void dispose() {
    _geocodeTimer?.cancel();
    _geocodeDio.close();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // ── Geocoding ─────────────────────────────────────────────────────────────

  void _onAddressChanged() {
    final q = _addressCtrl.text.trim();
    _geocodeTimer?.cancel();
    if (q.length < 3) {
      if (_geocoding || _suggestions.isNotEmpty) {
        setState(() {
          _suggestions = [];
          _suggestionsOpen = false;
          _geocoding = false;
        });
      }
      return;
    }
    if (!_geocoding) setState(() => _geocoding = true);
    _geocodeTimer = Timer(const Duration(milliseconds: 400), () async {
      final results = await _forward(q);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _suggestionsOpen = results.isNotEmpty;
        _geocoding = false;
      });
    });
  }

  Future<void> _geocodeForViewport(String query) async {
    final results = await _forward(query);
    if (!mounted || results.isEmpty) return;
    setState(() {
      _viewportLat = results[0].lat;
      _viewportLon = results[0].lon;
      _viewportZoom = 11;
    });
    _mapController?.flyTo(
      mb.CameraOptions(
        center: mb.Point(
          coordinates: mb.Position(_viewportLon, _viewportLat),
        ),
        zoom: 11,
      ),
      mb.MapAnimationOptions(duration: 600),
    );
  }

  Future<List<_GeoSuggestion>> _forward(String query) async {
    try {
      final encoded = Uri.encodeComponent(query);
      final response = await _geocodeDio.get<Map<String, dynamic>>(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$encoded.json',
        queryParameters: {
          'access_token': MapboxConfig.accessToken,
          'limit': '5',
          'types': 'address,place,poi',
        },
      );
      final features = response.data?['features'];
      if (features is! List) return const [];
      return features
          .whereType<Map<String, dynamic>>()
          .map(_GeoSuggestion.fromJson)
          .whereType<_GeoSuggestion>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<String?> _reverse(double lat, double lon) async {
    try {
      final response = await _geocodeDio.get<Map<String, dynamic>>(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$lon,$lat.json',
        queryParameters: {
          'access_token': MapboxConfig.accessToken,
          'limit': '1',
        },
      );
      final features = response.data?['features'];
      if (features is! List || features.isEmpty) return null;
      return (features[0] as Map<String, dynamic>)['place_name']?.toString();
    } catch (_) {
      return null;
    }
  }

  // ── Suggestion pick ───────────────────────────────────────────────────────

  void _pickSuggestion(_GeoSuggestion s) {
    _addressCtrl.removeListener(_onAddressChanged);
    _addressCtrl.text = s.placeName;
    _addressCtrl.addListener(_onAddressChanged);
    setState(() {
      _suggestions = [];
      _suggestionsOpen = false;
      _geocoding = false;
    });
    _placePinAt(s.lat, s.lon, flyTo: true);
  }

  // ── Map pin ───────────────────────────────────────────────────────────────

  Future<void> _placePinAt(
    double lat,
    double lon, {
    bool flyTo = false,
  }) async {
    setState(() {
      _pinLat = lat;
      _pinLon = lon;
      _pinPlaced = true;
    });

    if (flyTo) {
      _mapController?.flyTo(
        mb.CameraOptions(
          center: mb.Point(coordinates: mb.Position(lon, lat)),
          zoom: 14,
        ),
        mb.MapAnimationOptions(duration: 600),
      );
    }

    final geometry = mb.Point(coordinates: mb.Position(lon, lat));

    if (_pinAnnotation != null && _pinManager != null) {
      _pinAnnotation!.geometry = geometry;
      await _pinManager!.update(_pinAnnotation!);
    } else if (_pinManager != null) {
      _pinAnnotation = await _pinManager!.create(
        mb.CircleAnnotationOptions(
          geometry: geometry,
          circleColor: context.mapControlAccent.toARGB32(),
          circleRadius: 11.0,
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 2.5,
        ),
      );
    }
  }

  void _onMapTap(mb.MapContentGestureContext ctx) async {
    final coords = ctx.point.coordinates;
    final lon = (coords[0] as num).toDouble();
    final lat = (coords[1] as num).toDouble();
    await _placePinAt(lat, lon, flyTo: false);
    final addr = await _reverse(lat, lon);
    if (addr != null && mounted) {
      _addressCtrl.removeListener(_onAddressChanged);
      _addressCtrl.text = addr;
      _addressCtrl.addListener(_onAddressChanged);
      setState(() {
        _suggestions = [];
        _suggestionsOpen = false;
      });
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  String? _saveError;

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final addr = _addressCtrl.text.trim();
      await context.read<AiRouteApiClient>().setRouteHotel(
        routeId: widget.routeId,
        hotel: RouteHotelPayload(
          hotelName: name,
          address: addr.isEmpty ? null : addr,
          latitude: _pinLat,
          longitude: _pinLon,
          providerName: 'Manual',
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = _extractErrorMessage(e);
      setState(() => _saveError = msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saveError = 'Could not save hotel. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    final status = e.response?.statusCode;
    if (status == 500) return 'Server error. Please try again later.';
    if (status == 401) return 'Session expired. Please log in again.';
    return 'Could not save hotel. Please try again.';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final maxSheetHeight = size.height * 0.92;
    final cs = Theme.of(context).colorScheme;
    final t = context.vacanzaTokens;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = context.mapControlAccent;

    final panelColor = isLight
        ? context.lightGlassPanelColor.withValues(alpha: 0.98)
        : cs.surface.withValues(alpha: 0.98);

    final fieldFill = isLight
        ? context.lightGlassFieldFill
        : cs.surfaceContainerHighest;

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: t.cardBorder.withValues(alpha: 0.45)),
    );
    final fieldFocusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: accent.withValues(alpha: 0.9), width: 1.4),
    );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboard),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: isLight ? 14 : 0,
            sigmaY: isLight ? 14 : 0,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: isLight
                    ? accent.withValues(alpha: 0.18)
                    : t.cardBorder.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 34,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxSheetHeight),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: t.textSub.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Header
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.bed_double_fill,
                          size: 18,
                          color: accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Add Hotel',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: t.textMain,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed:
                              _saving
                                  ? null
                                  : () => Navigator.of(context).pop(),
                          child: Icon(
                            CupertinoIcons.xmark,
                            size: 22,
                            color: t.textSub,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Hotel name
                    _label('Hotel / place name *', t, accent),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameCtrl,
                      textInputAction: TextInputAction.next,
                      enabled: !_saving,
                      decoration: InputDecoration(
                        hintText: 'e.g. Grand Hyatt Paris',
                        filled: true,
                        fillColor: fieldFill,
                        border: fieldBorder,
                        enabledBorder: fieldBorder,
                        focusedBorder: fieldFocusBorder,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Address label + geocoding spinner
                    Row(
                      children: [
                        _label('Address', t, accent),
                        if (_geocoding) ...[
                          const SizedBox(width: 8),
                          CupertinoActivityIndicator(
                            radius: 7,
                            color: t.textSub,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Address field
                    TextField(
                      controller: _addressCtrl,
                      enabled: !_saving,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'Search address or tap the map',
                        filled: true,
                        fillColor: fieldFill,
                        border: fieldBorder,
                        enabledBorder: fieldBorder,
                        focusedBorder: fieldFocusBorder,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),

                    // Autocomplete suggestions
                    if (_suggestionsOpen && _suggestions.isNotEmpty)
                      _SuggestionsList(
                        suggestions: _suggestions,
                        tokens: t,
                        accent: accent,
                        isLight: isLight,
                        onPick: _pickSuggestion,
                      ),

                    const SizedBox(height: 12),

                    // Mini map
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        height: 200,
                        child: Stack(
                          children: [
                            mb.MapWidget(
                              key: const ValueKey('hotel-picker-map'),
                              cameraOptions: mb.CameraOptions(
                                center: mb.Point(
                                  coordinates: mb.Position(
                                    _viewportLon,
                                    _viewportLat,
                                  ),
                                ),
                                zoom: _viewportZoom,
                              ),
                              styleUri:
                                  isLight
                                      ? MapboxConfig.styleStandard
                                      : MapboxConfig.styleDark,
                              // Compete with parent scroll/sheet: map only receives unclaimed drags if null.
                              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                                Factory<OneSequenceGestureRecognizer>(
                                  () => EagerGestureRecognizer(),
                                ),
                              },
                              onMapCreated: (map) async {
                                _mapController = map;
                                _pinManager = await map.annotations
                                    .createCircleAnnotationManager();
                              },
                              onTapListener: _onMapTap,
                            ),
                            // Crosshair shown before first pin
                            if (!_pinPlaced)
                              IgnorePointer(
                                child: Center(
                                  child: Icon(
                                    CupertinoIcons.scope,
                                    size: 32,
                                    color: accent.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _pinPlaced
                          ? '📍 Pin placed — tap map to adjust'
                          : 'Tap on the map to place your hotel pin',
                      style: TextStyle(
                        fontSize: 12,
                        color: t.textSub,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Save error
                    if (_saveError != null) ...[
                      Text(
                        _saveError!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Save button
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      color: accent.withValues(alpha: 0.16),
                      disabledColor: accent.withValues(alpha: 0.08),
                      onPressed:
                          (_nameCtrl.text.trim().isEmpty || _saving)
                              ? null
                              : _save,
                      child: Text(
                        _saving ? 'Saving…' : 'Save Hotel',
                        style: TextStyle(
                          color: accent,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, dynamic t, Color accent) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: t.textSub,
        letterSpacing: 0.2,
      ),
    );
  }
}

// ─── Suggestion list ──────────────────────────────────────────────────────────

class _SuggestionsList extends StatelessWidget {
  final List<_GeoSuggestion> suggestions;
  final dynamic tokens;
  final Color accent;
  final bool isLight;
  final void Function(_GeoSuggestion) onPick;

  const _SuggestionsList({
    required this.suggestions,
    required this.tokens,
    required this.accent,
    required this.isLight,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg =
        isLight
            ? context.lightGlassPanelColor.withValues(alpha: 0.98)
            : cs.surfaceContainer;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.cardBorder.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < suggestions.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: tokens.cardBorder.withValues(alpha: 0.3),
                ),
              InkWell(
                onTap: () => onPick(suggestions[i]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.location_fill,
                        size: 14,
                        color: accent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suggestions[i].shortName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: tokens.textMain,
                              ),
                            ),
                            Text(
                              suggestions[i].placeName
                                  .replaceFirst(
                                    '${suggestions[i].shortName}, ',
                                    '',
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: tokens.textSub,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
