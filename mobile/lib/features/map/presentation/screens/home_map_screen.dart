import 'package:flutter/material.dart';

import '../../data/models/map_view_mode.dart';
import '../widgets/home_map/home_map_scaffold.dart';

/// Login sonrası kullanıcıyı karşılayan ana harita ekranı.
/// Bu ekran Mapbox gelene kadar sadece UI iskeleti + state içerir.
///
/// State:
/// - MapViewMode (2D/3D/Satellite)
/// - Recenter / Map style gibi butonlar şimdilik mock handler çağırır.
class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  MapViewMode _mode = MapViewMode.mode2D;

  /// Map görünüm modunu sıradaki moda alır (2D -> 3D -> SAT -> 2D).
  void _toggleMode() {
    setState(() {
      _mode = _mode.next();
    });
  }

  /// Map style / layer açma gibi aksiyonlar şimdilik placeholder.
  void _openMapStyle() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map style (mock)')),
    );
  }

  /// Recenter aksiyonu şimdilik placeholder.
  void _recenter() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recenter (mock)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomeMapScaffold(
      mode: _mode,
      onToggleMode: _toggleMode,
      onOpenMapStyle: _openMapStyle,
      onRecenter: _recenter,
    );
  }
}