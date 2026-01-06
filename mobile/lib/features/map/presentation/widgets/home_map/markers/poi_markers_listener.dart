import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../poi_search/presentation/bloc/poi_search_bloc.dart';
import '../../../../../poi_search/presentation/bloc/poi_search_state.dart';
import 'poi_markers_controller.dart';

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
  PoiSearchState? _lastProcessedState;

  @override
  void didUpdateWidget(covariant PoiMarkersListener oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.poiMarkers != widget.poiMarkers) {
      log('[PoiMarkersListener] controller changed -> reset last state');
      _lastProcessedState = null;

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

    if (markers == null || !markers.isReady) {
      log('[PoiMarkersListener] markers not ready -> skipping');
      return;
    }

    if (!force && _isSameState(state, _lastProcessedState)) {
      log('[PoiMarkersListener] same state -> skip');
      return;
    }

    _lastProcessedState = state;

    if (state.status == PoiSearchStatus.loading) {
      log('[PoiMarkersListener] loading -> clear markers');
      await markers.clear();
      return;
    }

    if (!state.hasUsableArea || state.status == PoiSearchStatus.idle) {
      log('[PoiMarkersListener] idle/no area -> clear markers');
      await markers.clear();
      return;
    }

    if (state.status == PoiSearchStatus.success) {
      log('[PoiMarkersListener] success -> render ${state.pois.length} POIs');
      await markers.setPois(state.pois);
      return;
    }

    if (state.status == PoiSearchStatus.error) {
      log('[PoiMarkersListener] error -> keeping current markers');
    }
  }

  bool _isSameState(PoiSearchState? a, PoiSearchState? b) {
    if (a == null || b == null) return false;
    return a.status == b.status &&
        a.pois == b.pois &&
        a.selectedArea == b.selectedArea &&
        a.areaSource == b.areaSource;
  }
}