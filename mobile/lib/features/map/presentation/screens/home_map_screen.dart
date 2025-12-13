import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/map_bloc.dart';
import '../bloc/map_event.dart';
import '../bloc/map_state.dart';
import '../widgets/home_map/home_map_scaffold.dart';

/// Login sonrası kullanıcıyı karşılayan ana harita ekranı.
/// 156 kapsamında state (mode + recenter) BLoC'tan okunur.
///
/// Mapbox 137 gelince:
/// - MapInitialized(controller) gerçek controller ile dispatch edilecek
/// - RecenterPressed event'inde controller üzerinden kamera resetlenecek
class HomeMapScreen extends StatelessWidget {
  const HomeMapScreen({super.key});

  void _openMapStyle(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map style (mock)')),
    );
  }

  void _recenterMockFeedback(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recenter (mock)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MapBloc(),
      child: BlocBuilder<MapBloc, MapState>(
        builder: (context, state) {
          return HomeMapScaffold(
            mode: state.viewMode,
            onOpenMapStyle: () => _openMapStyle(context),
            onToggleMode: () =>
                context.read<MapBloc>().add(const ToggleViewModePressed()),
            onRecenter: () {
              context.read<MapBloc>().add(const RecenterPressed());

              // Mapbox yokken kullanıcı hissi (opsiyonel)
              _recenterMockFeedback(context);
            },
          );
        },
      ),
    );
  }
}