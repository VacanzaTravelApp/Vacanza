import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../poi_search/presentation/bloc/area_query_bloc.dart';
import '../bloc/map_bloc.dart';
import '../bloc/map_event.dart';
import '../bloc/map_state.dart';
import '../widgets/home_map/home_map_scaffold.dart';

/// Login sonrası kullanıcıyı karşılayan ana harita ekranı.
/// - MapBloc: 2D/3D + recenter + drawing toggle
/// - AreaQueryBloc: viewport bbox + user selection (polygon) state
class HomeMapScreen extends StatelessWidget {
  const HomeMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MapBloc>(
          create: (_) => MapBloc(),
        ),
        BlocProvider<AreaQueryBloc>(
          create: (_) => AreaQueryBloc(),
        ),
      ],
      child: const _HomeMapView(),
    );
  }
}

class _HomeMapView extends StatelessWidget {
  const _HomeMapView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapBloc, MapState>(
      builder: (context, state) {
        return HomeMapScaffold(
          mode: state.viewMode,
          isDrawing: state.isDrawing,
          onToggleMode: () => context.read<MapBloc>().add(const ToggleViewModePressed()),
          onRecenter: () => context.read<MapBloc>().add(const RecenterPressed()),
          onToggleDrawing: () => context.read<MapBloc>().add(ToggleDrawingPressed()),
        );
      },
    );
  }
}