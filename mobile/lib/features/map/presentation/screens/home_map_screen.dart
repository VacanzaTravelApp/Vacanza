// ======================= home_map_screen.dart =======================
// lib/features/map/presentation/screens/home_map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../poi_search/data/api/poi_search_api_client.dart';
import '../../../poi_search/data/models/area_source.dart';
import '../../../poi_search/data/models/selected_area.dart';
import '../../../poi_search/data/repositories/poi_search_repository.dart';
import '../../../poi_search/data/repositories/poi_search_repository_impl.dart';
import '../../../poi_search/presentation/bloc/area_query_bloc.dart';
import '../../../poi_search/presentation/bloc/area_query_event.dart' as aq;
import '../../../poi_search/presentation/bloc/area_query_state.dart';
import '../../../poi_search/presentation/bloc/poi_search_bloc.dart';
import '../../../poi_search/presentation/bloc/poi_search_event.dart' as poi;
import '../../../poi_search/presentation/bloc/poi_search_state.dart';

import '../../../poi_search/presentation/widgets/area_results/area_results_bottom_sheet.dart';
import '../../../poi_search/presentation/widgets/poi_filter_panel.dart';

import '../bloc/map_bloc.dart';
import '../bloc/map_event.dart';
import '../bloc/map_state.dart';
import '../widgets/home_map/home_map_scaffold.dart';

class HomeMapScreen extends StatelessWidget {
  const HomeMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PoiSearchRepository>(
          create: (ctx) => PoiSearchRepositoryImpl(
            ctx.read<PoiSearchApiClient>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<MapBloc>(create: (_) => MapBloc()),
          BlocProvider<AreaQueryBloc>(create: (_) => AreaQueryBloc()),
          BlocProvider<PoiSearchBloc>(
            create: (ctx) => PoiSearchBloc(
              repo: ctx.read<PoiSearchRepository>(),
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

class _HomeMapViewState extends State<_HomeMapView> {
  bool _filtersOpen = false;
  bool _resultsOpen = false;

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

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // ================= AreaQuery -> PoiSearch wiring =================
        BlocListener<AreaQueryBloc, AreaQueryState>(
          listenWhen: (prev, next) => prev.context != next.context,
          listener: (context, state) {
            final ctx = state.context;

            // 1) Viewport -> PoiSearch viewport event
            if (ctx.areaSource == AreaSource.viewport && ctx.area is BboxArea) {
              context.read<PoiSearchBloc>().add(
                poi.ViewportChanged(ctx.area as BboxArea),
              );
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
          listenWhen: (prev, next) =>
          prev.status != next.status ||
              prev.areaSource != next.areaSource ||
              prev.pois != next.pois ||
              prev.selectedCategories != next.selectedCategories,
          listener: (context, state) {
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
      ],
      child: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          final poiState = context.watch<PoiSearchBloc>().state;

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
          );

          return HomeMapScaffold(
            mode: state.viewMode,
            isDrawing: state.isDrawing,
            onToggleMode: () =>
                context.read<MapBloc>().add(const ToggleViewModePressed()),
            onRecenter: () => context.read<MapBloc>().add(const RecenterPressed()),
            onToggleDrawing: () {
              final isDrawingNow = context.read<MapBloc>().state.isDrawing;

              if (isDrawingNow) {
                // ✅ Butondan kapatma: komple reset
                context.read<MapBloc>().add(SetDrawingEnabled(false));
                _closeResultsAndResetToViewport();
                if (_filtersOpen) _closeFilters();
                return;
              }

              context.read<MapBloc>().add(SetDrawingEnabled(true));
            },

            // ✅ manual filter tuşu -> blur preview OFF
            onOpenFilters: () => _openFilters(fromUserSelection: false),

            // ===== Filters overlay =====
            isFiltersOpen: _filtersOpen,
            onCloseFilters: _closeFilters,
            filtersPanel: PoiFilterPanel(
              onClose: _closeFilters,
            ),

            // ===== Results sheet (normal) =====
            isResultsOpen: _resultsOpen,
            resultsSheet: sheetWidget,

            // ===== Blur preview sadece polygon sonrası filter açıldıysa =====
            showResultsBlurUnderFilters: _filtersFromUserSelection,
          );
        },
      ),
    );
  }
}