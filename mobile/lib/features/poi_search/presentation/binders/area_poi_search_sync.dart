import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/area_source.dart';
import '../../data/models/selected_area.dart';
import '../bloc/area_query_bloc.dart';
import '../bloc/area_query_state.dart';
import '../bloc/poi_search_bloc.dart';
import '../bloc/poi_search_event.dart' as poi_evt;

/// AreaQueryBloc (viewport/userSelection) -> PoiSearchBloc (search eventleri) köprüsü.
///
/// Split sonrası MapCanvas artık PoiSearchBloc'a doğrudan viewport/polygon event atmadığı için
/// bu binder olmadan search hiç çalışmayabilir.
class AreaPoiSearchSync extends StatelessWidget {
  const AreaPoiSearchSync({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AreaQueryBloc, AreaQueryState>(
      listenWhen: (prev, next) {
        final p = prev.context;
        final n = next.context;
        return p.areaSource != n.areaSource || p.area != n.area;
      },
      listener: (context, state) {
        final q = state.context;
        final areaSource = q.areaSource;
        final area = q.area;

        if (kDebugMode) {
          debugPrint('[AreaPoiSearchSync] areaSource=$areaSource area=$area');
        }

        // Alan temizlenirse PoiSearch'i de temizle
        if (area is NoArea) {
          context.read<PoiSearchBloc>().add(const poi_evt.AreaCleared());
          return;
        }

        // Viewport bazlı search
        if (areaSource == AreaSource.viewport && area is BboxArea) {
          context.read<PoiSearchBloc>().add(poi_evt.ViewportChanged(area));
          return;
        }

        // Kullanıcı polygon seçtiyse
        if (areaSource == AreaSource.userSelection && area is PolygonArea) {
          context.read<PoiSearchBloc>().add(poi_evt.AreaChanged(area));
          return;
        }
      },
      child: const SizedBox.shrink(),
    );
  }
}