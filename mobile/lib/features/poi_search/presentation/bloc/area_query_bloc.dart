import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/area_source.dart';

import '../../data/models/selected_area.dart';
import 'area_query_event.dart';
import 'area_query_state.dart';

class AreaQueryBloc extends Bloc<AreaQueryEvent, AreaQueryState> {
  AreaQueryBloc() : super(AreaQueryState.initial()) {
    on<ViewportChanged>(_onViewportChanged);
  }

  void _onViewportChanged(
      ViewportChanged event,
      Emitter<AreaQueryState> emit,
      ) {
    final current = state.context;

    // ✅ USER_SELECTION aktifse viewport bbox state’i değiştirmesin.
    if (current.areaSource == AreaSource.userSelection) return;

    // ✅ Aynı bbox geldiyse spam emit etme.
    if (current.area is BboxArea && current.area == event.bbox) return;

    emit(
      AreaQueryState(
        context: current.copyWith(
          areaSource: AreaSource.viewport,
          area: event.bbox,
        ),
      ),
    );
  }
}