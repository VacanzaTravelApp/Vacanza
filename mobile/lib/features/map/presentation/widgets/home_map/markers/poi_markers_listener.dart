import 'dart:developer';
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
class PoiMarkersListener extends StatefulWidget {
  final PoiMarkersController? poiMarkers;

  const PoiMarkersListener({
    super.key,
    required this.poiMarkers,
  });

  @override
  State<PoiMarkersListener> createState() => _PoiMarkersListenerState();
}

class _PoiMarkersListenerState extends State<PoiMarkersListener> {
  /// ✅ En son işlenen POI state'ini tut (gereksiz duplicate işlemleri engeller)
  PoiSearchState? _lastProcessedState;

  @override
  void didUpdateWidget(covariant PoiMarkersListener oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ Controller değiştiyse (style change sonrası) state'i resetle
    if (oldWidget.poiMarkers != widget.poiMarkers) {
      log('[PoiMarkersListener] controller changed, resetting state');
      _lastProcessedState = null;

      // ✅ Yeni controller'a mevcut POI state'ini uygula
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final currentState = context.read<PoiSearchBloc>().state;
        _processPoisState(currentState, force: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PoiSearchBloc, PoiSearchState>(
      listenWhen: (prev, next) {
        // ✅ Sadece gerçekten değişen state'leri işle
        return prev.status != next.status ||
            prev.pois != next.pois ||
            prev.selectedArea != next.selectedArea ||
            prev.areaSource != next.areaSource;
      },
      listener: (context, state) {
        _processPoisState(state);
      },
      child: const SizedBox.shrink(),
    );
  }

  void _processPoisState(PoiSearchState state, {bool force = false}) async {
    final markers = widget.poiMarkers;

    if (markers == null) {
      log('[PoiMarkersListener] markers=null, skipping');
      return;
    }

    // ✅ Duplicate işlem engelle (force=true ise atla)
    if (!force && _isSameState(state, _lastProcessedState)) {
      log('[PoiMarkersListener] same state, skipping duplicate processing');
      return;
    }

    _lastProcessedState = state;

    // ✅ Loading -> temizle
    if (state.status == PoiSearchStatus.loading) {
      log('[PoiMarkersListener] loading -> clear markers');
      await markers.clear();
      return;
    }

    // ✅ Alan yoksa veya idle -> temizle
    if (!state.hasUsableArea || state.status == PoiSearchStatus.idle) {
      log('[PoiMarkersListener] no usable area or idle -> clear markers');
      await markers.clear();
      return;
    }

    // ✅ Success -> POI'leri bas
    if (state.status == PoiSearchStatus.success) {
      log('[PoiMarkersListener] success -> rendering ${state.pois.length} POIs');
      await markers.setPois(state.pois);
      return;
    }

    // ✅ Error durumunda mevcut marker'ları korumak istersen clear yapma
    if (state.status == PoiSearchStatus.error) {
      log('[PoiMarkersListener] error -> keeping current markers');
      // await markers.clear(); // İstersen aç
    }
  }

  /// ✅ İki state'in POI rendering açısından aynı olup olmadığını kontrol et
  bool _isSameState(PoiSearchState? a, PoiSearchState? b) {
    if (a == null || b == null) return false;

    return a.status == b.status &&
        a.pois == b.pois &&
        a.selectedArea == b.selectedArea &&
        a.areaSource == b.areaSource;
  }
}