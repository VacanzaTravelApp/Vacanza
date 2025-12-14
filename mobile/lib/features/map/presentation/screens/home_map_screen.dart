import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/map_view_mode.dart';
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
    return BlocBuilder<MapBloc, MapState>(
      builder: (context, state) {
        return HomeMapScaffold(
          mode: state.viewMode,
          onToggleMode: () => context.read<MapBloc>().add(const ToggleViewModePressed()),
          onRecenter: () => context.read<MapBloc>().add(const RecenterPressed()),
        );
      },
    );
  }
}