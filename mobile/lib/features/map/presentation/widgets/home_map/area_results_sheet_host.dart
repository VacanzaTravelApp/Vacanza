// ======================= area_results_sheet_host.dart =======================
// lib/features/map/presentation/widgets/home_map/area_results_sheet_host.dart
//
// NOT: Bu host'u artık HomeMapScreen içinde sheet'i direkt veriyoruz diye
// şart değil. Ama senin projede duruyorsa ve kullanacaksan, güncel hali bu.
//
// Eğer kullanmıyorsan silebilirsin; kullanıyorsan aşağıdaki versiyon compile eder.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../poi_search/data/models/area_source.dart';
import '../../../../poi_search/data/models/selected_area.dart';
import '../../../../poi_search/presentation/bloc/area_query_bloc.dart';
import '../../../../poi_search/presentation/bloc/area_query_event.dart' as aq;
import '../../../../poi_search/presentation/bloc/poi_search_bloc.dart';
import '../../../../poi_search/presentation/bloc/poi_search_event.dart' as ps;
import '../../../../poi_search/presentation/bloc/poi_search_state.dart';
import '../../../../poi_search/presentation/widgets/area_results/area_results_bottom_sheet.dart';

class AreaResultsSheetHost extends StatefulWidget {
  const AreaResultsSheetHost({super.key});

  @override
  State<AreaResultsSheetHost> createState() => _AreaResultsSheetHostState();
}

class _AreaResultsSheetHostState extends State<AreaResultsSheetHost> {
  /// null => All
  String? _activeChipKey;

  void _onChipSelected(String? key) {
    // ✅ UI filter only (backend'e request yok)
    setState(() => _activeChipKey = key);
  }

  void _handleClose(BuildContext context) {
    // ✅ A senaryosu: sheet kapanınca viewport moduna dön
    context.read<AreaQueryBloc>().add(const aq.ClearUserSelection());
    context.read<PoiSearchBloc>().add(const ps.AreaCleared());

    // ✅ Chip reset
    setState(() => _activeChipKey = null);
  }

  @override
  Widget build(BuildContext context) {
    // (AreaQueryBloc state'ini burada okumuyorsan, hasUserPolygon kontrolünü
    // HomeMapScreen zaten yaptığı için host'u kullanmana gerek yok.)
    final poiState = context.watch<PoiSearchBloc>().state;

    // minimal show: başarı geldiyse göster
    final showSheet = poiState.status == PoiSearchStatus.success;

    return AreaResultsSheet(
      isVisible: showSheet,
      count: poiState.count,
      pois: poiState.pois,
      countsByCategory: poiState.countsByCategory,
      selectedCategories: poiState.selectedCategories,
      activeChipKey: _activeChipKey,
      onChipSelected: _onChipSelected,
      onClose: () => _handleClose(context),
    );
  }
}