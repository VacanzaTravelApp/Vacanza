import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/poi_search_bloc.dart';
import '../bloc/poi_search_event.dart';
import '../bloc/poi_search_state.dart';

/// VACANZA-188: POI Filter Panel (Categories + countsByCategory)
/// - countsByCategory varsa: count=0 olanları hafif "disabled" gösterir
/// - seç / kaldır: CategoryChanged event'i atar (bloc zaten yeniden search tetikliyor)
class PoiFilterPanel extends StatelessWidget {
  final VoidCallback onClose;

  const PoiFilterPanel({
    super.key,
    required this.onClose,
  });

  /// UI'da ilk sırada görmek istediklerin (figma ile uyumlu)
  static const List<String> _baseOrder = <String>[
    'restaurants',
    'cafe',
    'museum',
    'monuments',
    'parks',
  ];

  /// counts'da baseOrder dışı gelen kategoriler varsa onları da ekle (alfabetik)
  List<String> _orderedCategories(Map<String, int> counts) {
    final extra = counts.keys.where((k) => !_baseOrder.contains(k)).toList()
      ..sort();
    return <String>[..._baseOrder, ...extra];
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'restaurants':
        return Icons.restaurant_rounded;
      case 'cafe':
        return Icons.local_cafe_rounded;
      case 'museum':
        return Icons.museum_rounded;
      case 'monuments':
        return Icons.account_balance_rounded;
      case 'parks':
        return Icons.park_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  Color _colorFor(String key) {
    switch (key) {
      case 'museum':
        return const Color(0xFF0096FF); // blue
      case 'restaurants':
        return const Color(0xFFFFD166); // yellow
      case 'cafe':
        return const Color(0xFFB37AFF); // purple
      case 'monuments':
        return const Color(0xFFFF9F43); // orange
      case 'parks':
        return const Color(0xFF2ECC71); // green
      default:
        return const Color(0xFF0096FF);
    }
  }

  String _labelFor(String key) {
    switch (key) {
      case 'restaurants':
        return 'Restaurants';
      case 'cafe':
        return 'Cafes';
      case 'museum':
        return 'Museums';
      case 'monuments':
        return 'Monuments';
      case 'parks':
        return 'Parks';
      default:
        if (key.isEmpty) return key;
        return key[0].toUpperCase() + key.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PoiSearchBloc, PoiSearchState>(
      builder: (context, state) {
        final counts = state.countsByCategory;
        final hasCounts = counts.isNotEmpty;

        // counts boşsa da panel boş kalmasın diye baseOrder gösteriyoruz
        final categories = hasCounts ? _orderedCategories(counts) : _baseOrder;

        final selected = state.selectedCategories.toSet();

        return Container(
          width: 165, // daha ince
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ---------------- Header ----------------
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filter POIs',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onClose,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 8),

              // ---------------- Items ----------------
              ...categories.map((key) {
                final count = counts[key] ?? 0;

                // counts geldiyse count=0 olanlar disabled görünsün
                final enabled = !hasCounts || count > 0;

                final isOn = selected.contains(key);
                final color = _colorFor(key);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: enabled
                        ? () {
                      final next = Set<String>.from(selected);

                      if (isOn) {
                        next.remove(key);
                      } else {
                        next.add(key);
                      }

                      // Bloc: category değişince aynı aktif area ile tekrar search atıyor.
                      context
                          .read<PoiSearchBloc>()
                          .add(CategoryChanged(next.toList()));
                    }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isOn ? color.withOpacity(0.10) : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          // icon bubble
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: enabled
                                  ? color.withOpacity(isOn ? 0.18 : 0.10)
                                  : Colors.grey.withOpacity(0.10),
                            ),
                            child: Icon(
                              _iconFor(key),
                              size: 14,
                              color: enabled
                                  ? (isOn ? color : Colors.grey.shade500)
                                  : Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // label
                          Expanded(
                            child: Text(
                              _labelFor(key),
                              style: TextStyle(
                                fontSize: 12,
                                color: enabled
                                    ? (isOn
                                    ? Colors.black87
                                    : Colors.grey.shade700)
                                    : Colors.grey.shade400,
                                fontWeight:
                                isOn ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),

                          // count badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10,
                                color: enabled
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade400,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}