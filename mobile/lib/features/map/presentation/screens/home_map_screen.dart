import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../poi_search/data/api/poi_search_api_client.dart';
import '../../../poi_search/data/models/area_source.dart';
import '../../../poi_search/data/models/selected_area.dart';
import '../../../poi_search/data/repositories/poi_search_repository.dart';
import '../../../poi_search/data/repositories/poi_search_repository_impl.dart';
import '../../../poi_search/presentation/bloc/area_query_bloc.dart';
import '../../../poi_search/presentation/bloc/area_query_state.dart';
import '../../../poi_search/presentation/bloc/poi_search_bloc.dart';
import '../../../poi_search/presentation/bloc/poi_search_event.dart' as poi;

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

  void _openFilters() {
    if (_filtersOpen) return;
    if (!mounted) return;
    setState(() => _filtersOpen = true);
  }

  void _closeFilters() {
    if (!_filtersOpen) return;
    if (!mounted) return;
    setState(() => _filtersOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
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
            if (ctx.areaSource == AreaSource.userSelection) {
              context.read<PoiSearchBloc>().add(poi.AreaChanged(ctx.area));
              _openFilters();
              return;
            }

            // 3) No usable area -> clear (+ istersek paneli kapat)
            if (!ctx.hasUsableArea) {
              context.read<PoiSearchBloc>().add(const poi.AreaCleared());
              _closeFilters();
            }
          },
        ),
      ],
      child: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          return HomeMapScaffold(
            mode: state.viewMode,
            isDrawing: state.isDrawing,
            onToggleMode: () =>
                context.read<MapBloc>().add(const ToggleViewModePressed()),
            onRecenter: () =>
                context.read<MapBloc>().add(const RecenterPressed()),
            onToggleDrawing: () =>
                context.read<MapBloc>().add(ToggleDrawingPressed()),
            onOpenFilters: _openFilters,

            // ✅ Overlay kontrolü burada
            isFiltersOpen: _filtersOpen,
            onCloseFilters: _closeFilters,
            filtersPanel: PoiFilterPanel(
              onClose: _closeFilters,
            ),
          );
        },
      ),
    );
  }
}