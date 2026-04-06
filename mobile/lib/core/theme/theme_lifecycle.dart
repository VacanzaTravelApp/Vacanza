import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme_cubit.dart';

/// Arka plandan dönünce zamanlanmış temayı tekrar hesaplar.
class ThemeLifecycle extends StatefulWidget {
  const ThemeLifecycle({super.key, required this.child});

  final Widget child;

  @override
  State<ThemeLifecycle> createState() => _ThemeLifecycleState();
}

class _ThemeLifecycleState extends State<ThemeLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ThemeCubit>().reevaluateSchedule();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
