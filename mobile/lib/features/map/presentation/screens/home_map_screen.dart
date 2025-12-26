import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../poi_search/data/api/poi_search_api_client.dart';
import '../../../poi_search/data/api/poi_search_in_area_request_dto.dart'; // PoiSort buradan geliyor
import '../../../poi_search/data/repositories/poi_search_repository.dart';
import '../../../poi_search/data/repositories/poi_search_repository_impl.dart';
import '../../../poi_search/presentation/bloc/area_query_bloc.dart';
import '../../../poi_search/presentation/bloc/area_query_state.dart';
import '../../../poi_search/presentation/bloc/poi_search_bloc.dart';

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

class _HomeMapView extends StatelessWidget {
  const _HomeMapView();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AreaQueryBloc, AreaQueryState>(
          listenWhen: (prev, next) => prev.context != next.context,
          listener: (context, state) {
            if (!state.context.hasUsableArea) return;

            context.read<PoiSearchBloc>().fetchForArea(
              area: state.context.area,
              categories: const ["museum", "restaurant"], // mock
              sort: PoiSort.distanceToCenter,
              limit: 200,
            );
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
          );
        },
      ),
    );
  }
}