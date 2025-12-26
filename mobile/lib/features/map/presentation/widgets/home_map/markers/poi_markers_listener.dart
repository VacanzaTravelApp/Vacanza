import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../poi_search/data/models/poi.dart';
import '../../../../../poi_search/presentation/bloc/poi_search_bloc.dart';
import '../../../../../poi_search/presentation/bloc/poi_search_state.dart';

import 'poi_markers_controller.dart';

/// PoiSearchBloc -> Map markers binder.
/// UI çizmez; sadece marker state sync yapar.
class PoiMarkersListener extends StatelessWidget {
  final PoiMarkersController? poiMarkers;

  /// Backend boş dönerse mock gösterelim mi?
  /// Backend gelince false yapıp sadece gerçek data kullanabilirsin.
  final bool useMockWhenBackendEmpty;

  /// Mock data üretici (backend boşken dev/test için).
  final List<Poi> Function()? mockPois;

  const PoiMarkersListener({
    super.key,
    required this.poiMarkers,
    required this.useMockWhenBackendEmpty,
    this.mockPois,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<PoiSearchBloc, PoiSearchState>(
      listenWhen: (prev, next) =>
      prev.status != next.status ||
          prev.pois != next.pois ||
          prev.selectedCategories != next.selectedCategories,
      listener: (context, state) async {
        final markers = poiMarkers;
        if (markers == null) {
          if (kDebugMode) {
            debugPrint('[PoiMarkersListener] markers=null (init sonrası setState gerekli)');
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

        // Success -> marker bas
        if (state.status == PoiSearchStatus.success) {
          // 1) Data kaynağı seçimi
          List<Poi> pois = state.pois;

          if (pois.isEmpty && useMockWhenBackendEmpty && mockPois != null) {
            pois = mockPois!();
          }

          // 2) Kategori filtresi (mock + backend fark etmez)
          final selected = state.selectedCategories
              .map((e) => e.trim().toLowerCase())
              .where((e) => e.isNotEmpty)
              .toSet();

          if (selected.isNotEmpty) {
            pois = pois
                .where((p) => selected.contains(p.category.trim().toLowerCase()))
                .toList();
          }

          if (kDebugMode) {
            debugPrint(
              '[PoiMarkersListener] status=success backendPois=${state.pois.length} '
                  'selected=${selected.length} renderPois=${pois.length}',
            );
          }

          await markers.setPois(pois);
        }
      },
      child: const SizedBox.shrink(),
    );
  }
}