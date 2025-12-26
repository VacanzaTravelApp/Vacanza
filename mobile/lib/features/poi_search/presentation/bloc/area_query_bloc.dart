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

  void _onViewportChanged(
      ViewportChanged event,
      Emitter<AreaQueryState> emit,
      ) {
    final current = state.context;

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

    // Alanı NoArea yapıyoruz; viewport bbox zaten MapCanvas'tan gelmeye devam edecek.
    emit(
      state.copyWith(
        context: current.copyWith(
          areaSource: AreaSource.viewport,
          area: const NoArea(),
        ),
      ),
    );
  }
}