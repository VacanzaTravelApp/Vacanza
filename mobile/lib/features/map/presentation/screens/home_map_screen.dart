// ======================= home_map_screen.dart =======================
// lib/features/map/presentation/screens/home_map_screen.dart
import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import 'package:mobile/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:mobile/features/behavior/presentation/cubit/favorite_poi_cubit.dart';
import 'package:mobile/features/behavior/presentation/cubit/saved_pois_cubit.dart';
import 'package:mobile/features/behavior/presentation/widgets/saved_pois_panel.dart';

import '../../../checkin/data/api/checkin_api_client.dart';
import '../../../checkin/data/repositories/checkin_repository.dart';
import '../../../checkin/data/services/location_service.dart';
import '../../../checkin/presentation/bloc/candidate_poi_cubit.dart';
import '../../../checkin/presentation/bloc/checkin_bloc.dart';
import '../../../checkin/presentation/bloc/checkin_event.dart';
import '../../../checkin/presentation/bloc/checkin_state.dart';
import '../../../checkin/presentation/bloc/location_bloc.dart';
import '../../../checkin/presentation/bloc/location_event.dart';
import '../../../checkin/presentation/bloc/location_state.dart';

import '../../../gamification/presentation/cubit/gamification_cubit.dart';

import '../../../poi_search/data/api/poi_search_api_client.dart';
import '../../../poi_search/data/models/area_source.dart';
import '../../../poi_search/data/models/selected_area.dart';
import '../../../poi_search/data/repositories/composite_poi_search_repository.dart';
import '../../../poi_search/data/repositories/poi_search_repository.dart';
import '../../../poi_search/data/repositories/poi_search_repository_impl.dart';
import '../../../poi_search/data/services/style_poi_discovery_binding.dart';
import '../../../poi_search/presentation/bloc/area_query_bloc.dart';
import '../../../poi_search/presentation/bloc/area_query_event.dart' as aq;
import '../../../poi_search/presentation/bloc/area_query_state.dart';
import '../../../poi_search/presentation/bloc/poi_search_bloc.dart';
import '../../../poi_search/presentation/bloc/poi_search_event.dart' as poi;
import '../../../poi_search/presentation/bloc/poi_search_state.dart';

import '../../../poi_search/presentation/widgets/area_results/area_results_bottom_sheet.dart';
import '../../../poi_search/presentation/widgets/poi_filter_panel.dart';

import '../../../../features/booking/presentation/widgets/booking_bottom_sheet.dart';

import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../ai/utils/route_map.dart';
import '../../../ai/presentation/cubit/active_route_cubit.dart';
import '../../../ai/presentation/cubit/active_route_state.dart';
import '../../../ai/data/api/ai_route_api_client.dart';
import '../../../chat/data/api/chat_api_client.dart';
import '../widgets/home_map/route/route_bottom_sheet.dart';
import '../widgets/home_map/route/route_mini_pill.dart';
import '../../../trip_agenda/trip_agenda_calendar_sheet.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/bloc/profile_event.dart';
import '../../../ar/presentation/screens/ar_explore_page.dart';
import '../bloc/map_bloc.dart';
import '../bloc/map_event.dart';
import '../bloc/map_state.dart';
import '../widgets/create_route_from_area_options_sheet.dart';
import '../widgets/home_map/home_map_scaffold.dart';
import '../widgets/home_map/markers/poi_marker_detail_sheet.dart';

class HomeMapScreen extends StatelessWidget {
  const HomeMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<StylePoiDiscoveryBinding>(
          create: (_) => StylePoiDiscoveryBinding(),
        ),
        RepositoryProvider<PoiSearchRepository>(
          create:
              (ctx) => CompositePoiSearchRepository(
                backend: PoiSearchRepositoryImpl(
                  ctx.read<PoiSearchApiClient>(),
                ),
                styleBinding: ctx.read<StylePoiDiscoveryBinding>(),
              ),
        ),
        RepositoryProvider<LocationService>(create: (_) => LocationService()),
        RepositoryProvider<CheckinApiClient>(
          create: (ctx) => CheckinApiClient(ctx.read<Dio>()),
        ),
        RepositoryProvider<CheckinRepository>(
          create: (ctx) => CheckinRepository(ctx.read<CheckinApiClient>()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<MapBloc>(create: (_) => MapBloc()),
          BlocProvider<ActiveRouteCubit>(
            create:
                (ctx) => ActiveRouteCubit(
                  chatApi: ctx.read<ChatApiClient>(),
                  routeApi: ctx.read<AiRouteApiClient>(),
                ),
          ),
          BlocProvider<AreaQueryBloc>(create: (_) => AreaQueryBloc()),
          BlocProvider<PoiSearchBloc>(
            create:
                (ctx) => PoiSearchBloc(repo: ctx.read<PoiSearchRepository>()),
          ),
          BlocProvider<LocationBloc>(
            create:
                (ctx) =>
                    LocationBloc(locationService: ctx.read<LocationService>()),
          ),
          BlocProvider<CandidatePoiCubit>(create: (_) => CandidatePoiCubit()),
          BlocProvider<CheckinBloc>(
            create:
                (ctx) => CheckinBloc(repository: ctx.read<CheckinRepository>()),
          ),
          BlocProvider<ProfileBloc>(
            create:
                (ctx) => ProfileBloc(repository: ctx.read<ProfileRepository>()),
          ),
          BlocProvider<SavedPoisCubit>(
            create:
                (ctx) => SavedPoisCubit(
                  api: ctx.read(),
                  favoritePoiCubit: ctx.read<FavoritePoiCubit>(),
                ),
          ),
        ],
        child: const _HomeMapView(),
      ),
    );
  }
}

class _HomeMapView extends StatefulWidget {
  const _HomeMapView();

  @override
  State<_HomeMapView> createState() => _HomeMapViewState();
}

class _HomeMapViewState extends State<_HomeMapView>
    with WidgetsBindingObserver {
  bool _filtersOpen = false;
  bool _resultsOpen = false;
  bool _controlsMenuOpen = false;
  bool _routeOpen = false;
  bool _routeShowEventsInitially = false;
  bool _savedPlacesOpen = false;

  /// Cached reference to avoid context.read in dispose/lifecycle callbacks.
  late final LocationBloc _locationBloc;
  late final ChatCubit _chatCubit;

  /// GPS tracking was active before app went to background
  bool _wasTracking = false;

  /// ✅ Filter açılışı polygon çiziminden mi geldi?
  /// Sadece bu durumda results sheet altta blur preview olarak görünsün.
  bool _filtersFromUserSelection = false;

  /// ✅ Bottom sheet chip'leri sadece UI filter (backend'e istek atmaz)
  /// null => All
  String? _activeChipKey;

  void _openFilters({required bool fromUserSelection}) {
    if (_filtersOpen) return;
    if (!mounted) return;

    setState(() {
      _filtersOpen = true;
      _filtersFromUserSelection = fromUserSelection;

      // ✅ Chip her filter açılışında All'a dönsün
      _activeChipKey = null;

      // ✅ Blur preview için resultsOpen'ı zorla kapatmıyoruz.
      // Filter overlay varken normal showResults zaten kapalı;
      // scaffold blur preview'ı ayrı gösterecek.
    });
  }

  void _closeFilters() {
    if (!_filtersOpen) return;
    if (!mounted) return;

    setState(() {
      _filtersOpen = false;
      _filtersFromUserSelection = false;
      _activeChipKey = null; // ✅ filter kapanınca chip'i All'a resetle
    });

    // ✅ Filter kapanınca: eğer userSelection + success varsa sheet aç
    final ps = context.read<PoiSearchBloc>().state;
    if (ps.status == PoiSearchStatus.success &&
        ps.areaSource == AreaSource.userSelection &&
        ps.pois.isNotEmpty) {
      setState(() => _resultsOpen = true);
    }
  }

  void _closeResultsAndResetToViewport() {
    if (!mounted) return;

    setState(() {
      _resultsOpen = false;
      _activeChipKey = null;
    });

    // ✅ A senaryosu: selection temizle + viewport’a dön
    context.read<AreaQueryBloc>().add(const aq.ClearUserSelection());
    context.read<PoiSearchBloc>().add(const poi.AreaCleared());

    // ✅ drawing de kapansın (temiz)
    context.read<MapBloc>().add(SetDrawingEnabled(false));
  }

  /// If user has drawn a polygon, clear it when opening any other screen.
  void _dismissUserSelectionIfAny() {
    final ctx = context.read<AreaQueryBloc>().state.context;
    if (ctx.areaSource != AreaSource.userSelection) return;

    // Close panels first so UI doesn't flash.
    if (mounted) {
      setState(() {
        _resultsOpen = false;
        _activeChipKey = null;
        if (_filtersOpen) {
          _filtersOpen = false;
          _filtersFromUserSelection = false;
        }
      });
    }

    context.read<AreaQueryBloc>().add(const aq.ClearUserSelection());
    context.read<PoiSearchBloc>().add(const poi.AreaCleared());
    context.read<MapBloc>().add(SetDrawingEnabled(false));
  }

  void _toggleControlsMenu() {
    if (!mounted) return;
    setState(() => _controlsMenuOpen = !_controlsMenuOpen);
  }

  void _closeControlsMenu() {
    if (!_controlsMenuOpen) return;
    if (!mounted) return;
    setState(() => _controlsMenuOpen = false);
  }

  void _openSavedPlaces() {
    if (!mounted) return;
    _dismissUserSelectionIfAny();
    setState(() {
      _filtersOpen = false;
      _filtersFromUserSelection = false;
      _resultsOpen = false;
      _activeChipKey = null;
      _routeOpen = false;
      _savedPlacesOpen = true;
    });
    context.read<SavedPoisCubit>().refresh();
  }

  void _closeSavedPlaces() {
    if (!_savedPlacesOpen) return;
    if (!mounted) return;
    setState(() => _savedPlacesOpen = false);
  }

  /// Closes results (and filters), then shows the two-step wizard + loading.
  void _beginCreateRouteFromArea() {
    if (!mounted) return;
    setState(() {
      _resultsOpen = false;
      _activeChipKey = null;
      if (_filtersOpen) {
        _filtersOpen = false;
        _filtersFromUserSelection = false;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_createRouteFromAreaWithPrompt());
    });
  }

  Future<void> _createRouteFromAreaWithPrompt() async {
    final ctx = context.read<AreaQueryBloc>().state.context;
    if (ctx.areaSource != AreaSource.userSelection ||
        ctx.area is! PolygonArea) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draw an area on the map first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final poly = ctx.area as PolygonArea;
    final coords = poly.points
        .map((p) => <double>[p.lng, p.lat])
        .toList(growable: false);

    final options = await showCreateRouteFromAreaOptionsSheet(context);
    if (!mounted) return;
    if (options == null) {
      // User dismissed the Plan a Route popup → clear the drawn area too.
      context.read<MapBloc>().add(SetDrawingEnabled(false));
      context.read<AreaQueryBloc>().add(const aq.ClearUserSelection());
      context.read<PoiSearchBloc>().add(const poi.AreaCleared());
      return;
    }

    // Rota isteği başlarken çizimi ve poligon overlay’ini kaldır (koordinatlar zaten [coords]’ta).
    context.read<MapBloc>().add(SetDrawingEnabled(false));
    context.read<AreaQueryBloc>().add(const aq.ClearUserSelection());
    context.read<PoiSearchBloc>().add(const poi.AreaCleared());

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogCtx) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Row(
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    'Creating your route…',
                    style: Theme.of(dialogCtx).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      await context.read<ActiveRouteCubit>().createFromPolygon(
        coordinates: coords,
        totalDays: options.totalDays,
        travelStyle: options.travelStyle,
        categories: null,
        includeFavorites: options.includeFavorites,
      );
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locationBloc = context.read<LocationBloc>();
    _chatCubit = ChatCubit(
      context.read<ChatApiClient>(),
      context.read<AiRouteApiClient>(),
    )..startConversation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locationBloc.add(const StartTracking());
      context.read<ProfileBloc>().add(ProfileStarted());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Stop GPS tracking before disposal (use cached ref — context is unsafe here)
    _locationBloc.add(const StopTracking());
    _chatCubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App going to background — stop GPS to save battery
      if (_locationBloc.state.status == LocationStatus.tracking) {
        _wasTracking = true;
        _locationBloc.add(const StopTracking());
      }
    } else if (state == AppLifecycleState.resumed) {
      // App coming to foreground — restart GPS if it was active before
      if (_wasTracking) {
        _wasTracking = false;
        _locationBloc.add(const StartTracking());
      }
    }
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
              'Location permission is permanently denied. '
              'Please enable it from app settings to use check-in.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Geolocator.openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // ================= Location permission handling (MOB-1) =================
        BlocListener<LocationBloc, LocationState>(
          listenWhen: (prev, next) => prev.status != next.status,
          listener: (context, state) {
            if (state.status == LocationStatus.permissionDenied) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Location permission is required for check-in.',
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
            } else if (state.status == LocationStatus.permissionDeniedForever) {
              _showPermissionDeniedDialog(context);
            }
          },
        ),

        // ================= Auto check-in trigger (MOB-3) =================
        BlocListener<LocationBloc, LocationState>(
          listenWhen:
              (prev, next) =>
                  next.status == LocationStatus.tracking &&
                  (prev.latitude != next.latitude ||
                      prev.longitude != next.longitude),
          listener: (context, state) {
            final candidates =
                context.read<CandidatePoiCubit>().state.candidatePoiIds;
            context.read<CheckinBloc>().add(
              TriggerAutoCheckin(
                latitude: state.latitude!,
                longitude: state.longitude!,
                candidatePoiIds: candidates,
              ),
            );
          },
        ),

        // ================= New check-in feedback (MOB-5) =================
        BlocListener<CheckinBloc, CheckinState>(
          listenWhen:
              (prev, next) =>
                  prev.status != next.status &&
                  next.status == CheckinStatus.newCreated,
          listener: (context, state) {
            final poiName = state.response?.poiName;
            final message =
                poiName != null ? 'Checked in at $poiName' : 'Checked in!';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),

        // ================= Gamification refresh (MOB-12) =================
        BlocListener<CheckinBloc, CheckinState>(
          listenWhen:
              (prev, next) =>
                  prev.status != next.status &&
                  next.status == CheckinStatus.newCreated &&
                  next.gamificationTriggered &&
                  prev.response?.checkInId != next.response?.checkInId,
          listener: (context, state) {
            log(
              '[GAM_UI] MOB-12 refresh triggered — '
              'checkInId=${state.response?.checkInId}',
            );
            context.read<GamificationCubit>().refresh();
          },
        ),

        BlocListener<AreaQueryBloc, AreaQueryState>(
          listenWhen: (prev, next) => prev.context != next.context,
          listener: (context, state) {
            final ctx = state.context;

            // 1) Viewport -> PoiSearch viewport event + CandidatePoiCubit
            if (ctx.areaSource == AreaSource.viewport && ctx.area is BboxArea) {
              final bbox = ctx.area as BboxArea;
              context.read<PoiSearchBloc>().add(poi.ViewportChanged(bbox));
              // MOB-2: forward viewport bbox to candidate cubit
              context.read<CandidatePoiCubit>().updateViewport(bbox);
              return;
            }

            // 2) User selection -> PoiSearch area event + filtre panelini aç
            if (ctx.areaSource == AreaSource.userSelection &&
                ctx.area is PolygonArea) {
              context.read<PoiSearchBloc>().add(poi.AreaChanged(ctx.area));

              // ✅ polygon sonrası açılan filter -> blur preview ON
              _openFilters(fromUserSelection: true);
              return;
            }

            // 3) No usable area -> clear (+ UI kapat)
            if (!ctx.hasUsableArea) {
              context.read<PoiSearchBloc>().add(const poi.AreaCleared());

              if (_filtersOpen) _closeFilters();

              if (_resultsOpen) {
                // sadece kapat; reset zaten AreaCleared ile geldi
                if (mounted) {
                  setState(() {
                    _resultsOpen = false;
                    _activeChipKey = null;
                  });
                }
              }
            }
          },
        ),

        // ================= PoiSearch -> Results sheet visibility =================
        BlocListener<PoiSearchBloc, PoiSearchState>(
          listenWhen:
              (prev, next) =>
                  prev.status != next.status ||
                  prev.areaSource != next.areaSource ||
                  prev.pois != next.pois ||
                  prev.selectedCategories != next.selectedCategories,
          listener: (context, state) {
            // MOB-2: forward POI list to candidate cubit on any POI change
            context.read<CandidatePoiCubit>().updatePois(state.pois);
            // Filter açıkken normal results gösterme (blur preview scaffold'da)
            if (_filtersOpen) {
              return;
            }

            // User selection + success -> sheet aç
            if (state.status == PoiSearchStatus.success &&
                state.areaSource == AreaSource.userSelection &&
                state.pois.isNotEmpty) {
              if (!_resultsOpen && mounted) {
                setState(() {
                  _resultsOpen = true;
                  _activeChipKey = null; // ✅ yeni sonuç gelince All
                });
              }
              return;
            }

            // Viewport’a dönünce -> sheet kapat
            if (state.areaSource == AreaSource.viewport &&
                state.status == PoiSearchStatus.idle) {
              if (_resultsOpen && mounted) {
                setState(() {
                  _resultsOpen = false;
                  _activeChipKey = null;
                });
              }
            }
          },
        ),

        // ================= ActiveRoute -> open route sheet =================
        BlocListener<ActiveRouteCubit, ActiveRouteState>(
          listenWhen:
              (prev, next) =>
                  prev.status != next.status ||
                  prev.route != next.route ||
                  prev.errorMessage != next.errorMessage,
          listener: (context, state) {
            if (state.status == ActiveRouteStatus.ready &&
                state.route != null) {
              if (mounted) setState(() => _routeOpen = true);

              final ps = context.read<PoiSearchBloc>().state;
              // Çizilen alan akışı: sonuç sheet’i önceden kapatılmış olsa da (Create route sihirbazı)
              // user selection + poligon overlay mutlaka temizlensin.
              if (ps.areaSource == AreaSource.userSelection) {
                if (mounted && _resultsOpen) {
                  setState(() {
                    _resultsOpen = false;
                    _activeChipKey = null;
                  });
                }
                context.read<MapBloc>().add(SetDrawingEnabled(false));
                context.read<AreaQueryBloc>().add(
                  const aq.ClearUserSelection(),
                );
                context.read<PoiSearchBloc>().add(const poi.AreaCleared());
              }
            }
            if (state.status == ActiveRouteStatus.idle) {
              if (mounted) setState(() => _routeOpen = false);
            }
            if (state.status == ActiveRouteStatus.failure &&
                (state.errorMessage ?? '').isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          final poiState = context.watch<PoiSearchBloc>().state;
          final activeRouteState = context.watch<ActiveRouteCubit>().state;
          final areaCtx = context.watch<AreaQueryBloc>().state.context;
          final canCreateRouteFromArea =
              poiState.areaSource == AreaSource.userSelection &&
              areaCtx.area is PolygonArea;

          // resultsSheet widget (hem normal hem blur preview’da kullanılacak)
          final sheetWidget = AreaResultsSheet(
            isVisible: true, // görünürlük HomeMapScaffold kontrol edecek
            count: poiState.count,
            pois: poiState.pois,
            countsByCategory: poiState.countsByCategory,
            selectedCategories: poiState.selectedCategories,
            activeChipKey: _activeChipKey,
            onChipSelected: (String? key) {
              if (!mounted) return;
              setState(() => _activeChipKey = key); // null => All
            },
            onClose: _closeResultsAndResetToViewport,
            onPoiTap: (poi) => showPoiMarkerDetailSheet(context, poi),
            hideZeroCountCategories:
                poiState.areaSource == AreaSource.userSelection,
            showCreateRouteFromArea: canCreateRouteFromArea,
            isCreatingRoute:
                activeRouteState.status == ActiveRouteStatus.loading,
            onCreateRouteFromArea: _beginCreateRouteFromArea,
          );

          return HomeMapScaffold(
            basemap: state.basemap,
            perspective: state.perspective,
            isDrawing: state.isDrawing,
            onCycleBasemap:
                () => context.read<MapBloc>().add(const CycleBasemapPressed()),
            onTogglePerspective:
                () => context.read<MapBloc>().add(
                  const TogglePerspectivePressed(),
                ),
            onRecenter:
                () => context.read<MapBloc>().add(const RecenterPressed()),
            onToggleDrawing: () {
              final isDrawingNow = context.read<MapBloc>().state.isDrawing;

              if (isDrawingNow) {
                // Sadece çizim modunu kapat. Alan/POI reseti yalnızca sonuç sheet kapatma
                // veya geçerli bir poligon tamamlandığında (MapDrawingOverlay) yapılır;
                // aksi halde hiç çizmeden kapatınca gereksiz viewport yenilemesi olur.
                context.read<MapBloc>().add(SetDrawingEnabled(false));
                if (_filtersOpen) _closeFilters();
                return;
              }

              context.read<MapBloc>().add(SetDrawingEnabled(true));
            },

            // ✅ manual filter tuşu -> blur preview OFF
            onOpenFilters: () {
              _dismissUserSelectionIfAny();
              _openFilters(fromUserSelection: false);
            },

            // UC1.11 — Explore in AR entry point
            onOpenArMode: () {
              _dismissUserSelectionIfAny();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => BlocProvider.value(
                        value: context.read<CheckinBloc>(),
                        child: const ArExplorePage(),
                      ),
                ),
              );
            },

            // ✅ UC1.8-MOB1: booking entry point
            onOpenBooking: () {
              _dismissUserSelectionIfAny();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                isDismissible: true,
                enableDrag: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const BookingBottomSheet(),
              );
            },

            onOpenTripAgenda: () {
              _closeControlsMenu();
              _dismissUserSelectionIfAny();
              showTripAgendaCalendar(context);
            },

            // ✅ Chatbot
            onOpenChat: () async {
              _closeControlsMenu();
              _dismissUserSelectionIfAny();
              final nav = await Navigator.push<ChatScreenNavResult?>(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => BlocProvider.value(
                        value: _chatCubit,
                        child: const ChatScreen(),
                      ),
                ),
              );
              if (!context.mounted) return;
              if (nav == null) return;
              if (nav.startDrawAreaOnMap) {
                context.read<MapBloc>().add(SetDrawingEnabled(true));
                return;
              }
              final res = nav.response;
              final routeCubit = context.read<ActiveRouteCubit>();
              if (res.routeData != null) {
                routeCubit.setFromChatResponse(res);
              } else if (res.routeId != null &&
                  res.routeId!.trim().isNotEmpty) {
                await routeCubit.loadSavedRoute(res.routeId!.trim());
                if (!context.mounted) return;
                if (routeCubit.state.status != ActiveRouteStatus.ready) {
                  return;
                }
              } else {
                return;
              }
              context
                  .read<PoiSearchBloc>()
                  .add(const poi.HidePoiMarkers());
              setState(() {
                _routeShowEventsInitially = nav.openEventsInitially;
                _routeOpen = true;
              });
              void applyRouteFit() {
                if (!context.mounted) return;
                final routeModel = context.read<ActiveRouteCubit>().state.route;
                if (routeModel == null) return;
                // Frame the whole trip (all days), not only the first calendar day — avoids
                // "nothing happens until I tap Day 2" when the map stayed on the wrong extent.
                var wps = allWaypointsForMap(routeModel);
                if (wps.isEmpty) {
                  wps = waypointsForInitialMapDay(routeModel);
                }
                final b = boundsOfWaypoints(wps);
                final brg = bearingFirstToLast(wps);
                if (b == null) return;
                context.read<MapBloc>().add(
                  FitRouteBoundsRequested(
                    minLat: b.minLat,
                    maxLat: b.maxLat,
                    minLng: b.minLng,
                    maxLng: b.maxLng,
                    bearing: brg,
                  ),
                );
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                applyRouteFit();
              });
              Future<void>.delayed(const Duration(milliseconds: 280), () {
                if (context.mounted) applyRouteFit();
              });
            },

            onOpenSavedPlaces: _openSavedPlaces,

            // ===== Filters overlay =====
            isFiltersOpen: _filtersOpen,
            onCloseFilters: _closeFilters,
            filtersPanel: PoiFilterPanel(
              onClose: _closeFilters,
              hideZeroCountCategories:
                  poiState.areaSource == AreaSource.userSelection,
            ),

            // ===== Saved places overlay =====
            isSavedPlacesOpen: _savedPlacesOpen,
            onCloseSavedPlaces: _closeSavedPlaces,
            savedPlacesPanel: SavedPoisPanel(
              onClose: _closeSavedPlaces,
              onFlyTo: (lat, lon) {
                _closeSavedPlaces();
                context.read<MapBloc>().add(
                  FlyToPoiRequested(latitude: lat, longitude: lon),
                );
              },
            ),

            // ===== Controls menu =====
            isControlsMenuOpen: _controlsMenuOpen,
            onToggleControlsMenu: _toggleControlsMenu,
            onCloseControlsMenu: _closeControlsMenu,

            // ===== Results sheet (normal) =====
            isResultsOpen: _resultsOpen,
            resultsSheet: sheetWidget,

            // ===== Route sheet (AI route) =====
            isRouteOpen:
                _routeOpen &&
                activeRouteState.route != null &&
                (activeRouteState.status == ActiveRouteStatus.ready ||
                    activeRouteState.status == ActiveRouteStatus.loading),
            routeSheet:
                _routeOpen &&
                        activeRouteState.route != null &&
                        (activeRouteState.status == ActiveRouteStatus.ready ||
                            activeRouteState.status ==
                                ActiveRouteStatus.loading)
                    ? DraggableRouteBottomSheet(
                      initialEvents: _routeShowEventsInitially,
                      onClose: () {
                        context.read<ActiveRouteCubit>().hideRouteFromMap();
                        context
                            .read<PoiSearchBloc>()
                            .add(const poi.ShowPoiMarkers());
                        context
                            .read<MapBloc>()
                            .add(const RefreshViewportRequested());
                        if (mounted) setState(() => _routeOpen = false);
                      },
                    )
                    : null,

            // ===== Mini route pill =====
            showRouteMiniPill:
                activeRouteState.status == ActiveRouteStatus.ready &&
                activeRouteState.route != null &&
                !activeRouteState.showRouteOnMap &&
                !_filtersOpen &&
                !_resultsOpen &&
                !state.isDrawing,
            routeMiniPill:
                activeRouteState.status == ActiveRouteStatus.ready &&
                        activeRouteState.route != null &&
                        !activeRouteState.showRouteOnMap
                    ? RouteMiniPill(
                      day: activeRouteState.activeDay,
                          onOpen: () {
                            if (!mounted) return;
                            context
                                .read<PoiSearchBloc>()
                                .add(const poi.HidePoiMarkers());
                            context.read<ActiveRouteCubit>().showRouteOnMapAgain();
                            setState(() => _routeOpen = true);
                          },
                      onClear: () {
                        context.read<ActiveRouteCubit>().reset();
                        context
                            .read<PoiSearchBloc>()
                            .add(const poi.ShowPoiMarkers());
                        context
                            .read<MapBloc>()
                            .add(const RefreshViewportRequested());
                        if (mounted) setState(() => _routeOpen = false);
                      },
                    )
                    : null,

            // ===== Blur preview sadece polygon sonrası filter açıldıysa =====
            showResultsBlurUnderFilters: _filtersFromUserSelection,
          );
        },
      ),
    );
  }
}
