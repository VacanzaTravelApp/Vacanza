import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../poi_search/presentation/bloc/poi_search_bloc.dart';
import '../../../../../poi_search/presentation/bloc/poi_search_state.dart';
import 'poi_markers_controller.dart';

/// PoiSearchBloc -> Map markers binder.
/// UI çizmez; sadece marker state sync yapar.
///
/// Kurallar:
/// - loading: clear
/// - idle veya usable area yok: clear
/// - success: backend'in döndürdüğü state.pois aynen basılır
///   (kategori filtresi backend tarafında uygulanır, burada tekrar filtreleme yapılmaz)
class PoiMarkersListener extends StatelessWidget {
  final PoiMarkersController? poiMarkers;

  const PoiMarkersListener({
    super.key,
    required this.poiMarkers,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<PoiSearchBloc, PoiSearchState>(
      listenWhen: (prev, next) =>
      prev.status != next.status ||
          prev.pois != next.pois ||
          prev.selectedArea != next.selectedArea ||
          prev.areaSource != next.areaSource,
      listener: (context, state) async {
        final markers = poiMarkers;
        if (markers == null) {
          if (kDebugMode) {
            debugPrint('[PoiMarkersListener] markers=null (MapCanvas setState ile rebuild etmeli)');
          }
          return;
        }

        // Yeni request başlarken eski marker'ları temizle
        if (state.status == PoiSearchStatus.loading) {
          await markers.clear();
          return;
        }

        // Alan yoksa veya idle ise temiz tut
        if (!state.hasUsableArea || state.status == PoiSearchStatus.idle) {
          await markers.clear();
          return;
        }

        // Success -> backend pois'i aynen bas
        if (state.status == PoiSearchStatus.success) {
          if (kDebugMode) {
            debugPrint('[PoiMarkersListener] success -> render pois=${state.pois.length}');
          }
          await markers.setPois(state.pois);
        }

        // Error'da mevcut marker'ı olduğu gibi bırakmak istersen clear yapma.
        // İstersen aşağıdaki satırı açabilirsin:
        // if (state.status == PoiSearchStatus.error) await markers.clear();
      },
      child: const SizedBox.shrink(),
    );
  }
}