import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/area_source.dart';
import '../../data/models/selected_area.dart';
import 'area_query_event.dart';
import 'area_query_state.dart';

class AreaQueryBloc extends Bloc<AreaQueryEvent, AreaQueryState> {
  AreaQueryBloc() : super(AreaQueryState.initial()) {
    on<ViewportChanged>(_onViewportChanged);
    on<UserSelectionChanged>(_onUserSelectionChanged);
    on<ClearUserSelection>(_onClearUserSelection);
  }

  /// Son gelen viewport bbox’u cache’leriz ki user selection temizlenince
  /// map hareket etmese bile hemen viewport alanına dönebilelim.
  BboxArea? _lastViewportBbox;

  void _onViewportChanged(
      ViewportChanged event,
      Emitter<AreaQueryState> emit,
      ) {
    final current = state.context;

    // ✅ Her zaman cache’le (USER_SELECTION aktif olsa bile).
    _lastViewportBbox = event.bbox;

    // ✅ USER_SELECTION aktifken viewport event'leri state'i bozmasın.
    if (current.areaSource == AreaSource.userSelection) {
      if (kDebugMode) {
        log('[AreaQueryBloc] IGNORE viewport (USER_SELECTION aktif)');
      }
      return;
    }

    // ✅ Aynı bbox geldiyse spam emit etme.
    if (current.area is BboxArea && current.area == event.bbox) {
      if (kDebugMode) {
        log('[AreaQueryBloc] IGNORE same bbox');
      }
      return;
    }

    if (kDebugMode) {
      log('[AreaQueryBloc] viewport bbox -> ${event.bbox}');
    }

    emit(
      state.copyWith(
        context: current.copyWith(
          areaSource: AreaSource.viewport,
          area: event.bbox,
        ),
      ),
    );
  }

  void _onUserSelectionChanged(
      UserSelectionChanged event,
      Emitter<AreaQueryState> emit,
      ) {
    final current = state.context;

    if (kDebugMode) {
      log('[AreaQueryBloc] USER_SELECTION -> ${event.area}');
    }

    emit(
      state.copyWith(
        context: current.copyWith(
          areaSource: AreaSource.userSelection,
          area: event.area,
        ),
      ),
    );
  }

  void _onClearUserSelection(
      ClearUserSelection event,
      Emitter<AreaQueryState> emit,
      ) {
    final current = state.context;

    if (kDebugMode) {
      log('[AreaQueryBloc] CLEAR USER_SELECTION -> back to viewport');
    }

    // ✅ Eğer son viewport bbox varsa direkt ona dön, yoksa NoArea.
    final fallback = _lastViewportBbox ?? const NoArea();

    emit(
      state.copyWith(
        context: current.copyWith(
          areaSource: AreaSource.viewport,
          area: fallback,
        ),
      ),
    );
  }
}