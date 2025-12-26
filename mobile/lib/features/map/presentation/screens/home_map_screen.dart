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
        /// ✅ VACANZA-186: UI/Bloc Dio görmesin diye repository katmanı
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

          /// ✅ VACANZA-187: POI search state management
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
        /// AreaQueryContext değişince POI search akışını tetikle
        BlocListener<AreaQueryBloc, AreaQueryState>(
          listenWhen: (prev, next) => prev.context != next.context,
          listener: (context, state) {
            final ctx = state.context;

            // 1) Viewport akışı (bbox)
            if (ctx.areaSource == AreaSource.viewport && ctx.area is BboxArea) {
              context
                  .read<PoiSearchBloc>()
                  .add(poi.ViewportChanged(ctx.area as BboxArea));
              return;
            }

            // 2) User selection akışı (bbox veya polygon olabilir)
            if (ctx.areaSource == AreaSource.userSelection) {
              context.read<PoiSearchBloc>().add(poi.AreaChanged(ctx.area));
              return;
            }

            // 3) Kullanılabilir area yoksa (NoArea vs) temizle
            if (!ctx.hasUsableArea) {
              context.read<PoiSearchBloc>().add(const poi.AreaCleared());
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
          );
        },
      ),
    );
  }
}