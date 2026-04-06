import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/poi_category_catalog.dart';
import '../bloc/poi_search_bloc.dart';
import '../bloc/poi_search_event.dart';
import '../bloc/poi_search_state.dart';

/// VACANZA-188: POI Filter Panel (Categories + countsByCategory)
/// Web [UI_CATEGORIES] ile hizalı katalog.
class PoiFilterPanel extends StatelessWidget {
  final VoidCallback onClose;

  const PoiFilterPanel({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PoiSearchBloc, PoiSearchState>(
      builder: (context, state) {
        final counts = state.countsByCategory;
        // Yalnızca katalogdaki 11 kategori; backend’den gelen yabancı count anahtarlarını gösterme.
        final categories =
            PoiCategoryCatalog.all.map((e) => e.key).toList(growable: false);

        final selected = state.selectedCategories.toSet();

        return SizedBox(
          width: 200,
          height: 400,
          child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final key in categories)
                          _FilterRow(
                            catKey: key,
                            counts: counts,
                            selected: selected,
                            onToggle: (next) {
                              context
                                  .read<PoiSearchBloc>()
                                  .add(CategoryChanged(next.toList()));
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String catKey;
  final Map<String, int> counts;
  final Set<String> selected;
  final void Function(Set<String> next) onToggle;

  const _FilterRow({
    required this.catKey,
    required this.counts,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final def = PoiCategoryCatalog.definitionForUiKey(catKey);
    final count = counts[catKey] ?? 0;
    final isOn = selected.contains(catKey);
    final color = def?.ringColor ?? const Color(0xFF0096FF);
    final icon = def?.iconData ?? Icons.place_rounded;
    final label = def?.label ?? catKey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final next = Set<String>.from(selected);
          if (isOn) {
            next.remove(catKey);
          } else {
            next.add(catKey);
          }
          onToggle(next);
        },
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
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(isOn ? 0.18 : 0.10),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: isOn ? color : Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isOn ? Colors.black87 : Colors.grey.shade700,
                    fontWeight: isOn ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
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
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
