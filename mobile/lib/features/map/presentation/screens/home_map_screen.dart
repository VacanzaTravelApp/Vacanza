import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/map_bloc.dart';
import '../bloc/map_event.dart';
import '../bloc/map_state.dart';
import '../widgets/home_map/home_map_scaffold.dart';

/// Login sonrası kullanıcıyı karşılayan ana harita ekranı.
/// Task 138: Toggle/Recenter aksiyonları BLoC'a dispatch eder.
class HomeMapScreen extends StatelessWidget {
  const HomeMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MapBloc>(
      // Bu ekran açılınca MapBloc oluşturulur.
      create: (_) => MapBloc(),
      child: const _HomeMapView(),
    );
  }
}

/// Provider'dan gelen MapBloc state'ini dinleyen gerçek UI.
/// (Provider ile UI'yi ayırıyoruz ki test/okunabilirlik iyi olsun.)
class _HomeMapView extends StatelessWidget {
  const _HomeMapView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapBloc, MapState>(
      builder: (context, state) {
        return HomeMapScaffold(
          mode: state.viewMode,
        //  onOpenMapStyle: () {
            // Task 138 kapsamı değil; şimdilik boş bırak.
         // },
          onToggleMode: () {
            context.read<MapBloc>().add(ToggleViewModePressed());
          },
          onRecenter: () {
            context.read<MapBloc>().add(RecenterPressed());
          },
        );
      },
    );
  }
}