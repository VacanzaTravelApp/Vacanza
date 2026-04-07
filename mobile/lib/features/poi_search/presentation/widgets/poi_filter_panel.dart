import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';

import '../../data/models/poi_category_catalog.dart';
import '../bloc/poi_search_bloc.dart';
import '../bloc/poi_search_event.dart';
import '../bloc/poi_search_state.dart';

/// VACANZA-188: POI Filter Panel (Categories + countsByCategory)
/// Web [UI_CATEGORIES] ile hizalı katalog.
///
/// [hideZeroCountCategories]: yalnızca alan çizimi (user selection) akışında `true` —
/// viewport’ta tüm kategoriler listelenir; 0 gizleme sadece çizim sonrası için.
class PoiFilterPanel extends StatelessWidget {
  final VoidCallback onClose;

  /// Alan çizimi sonrası: bu alanda 0 POI olan satırları gösterme.
  final bool hideZeroCountCategories;

  const PoiFilterPanel({
    super.key,
    required this.onClose,
    this.hideZeroCountCategories = false,
  });

  static List<String> _allCatalogKeys() =>
      PoiCategoryCatalog.all.map((e) => e.key).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PoiSearchBloc, PoiSearchState>(
      builder: (context, state) {
        final cs = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final accent = context.mapControlAccent;
        final secondary = cs.secondary;
        final counts = state.countsByCategory;
        final allKeys = _allCatalogKeys();
        // Çizim akışında: bu alanda gerçekten 0 POI olan satırları gösterme (sayılar tam listeden).
        final categories = hideZeroCountCategories
            ? allKeys
                .where((key) => (counts[key] ?? 0) > 0)
                .toList(growable: false)
            : allKeys;

        final selected = state.selectedCategories.toSet();

        const radius = 18.0;
        // Slightly more opaque than bare surface@0.76 so the map does not read muddy gray.
        final panelTint = isDark
            ? cs.surface.withValues(alpha: 0.88)
            : context.lightGlassPanelColor;

        return SizedBox(
          width: 200,
          height: 400,
          // Shadow outside clip so rounded corners stay clean (no square corner bleed).
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: isDark ? 0.28 : 0.12),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              clipBehavior: Clip.antiAlias,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                // No [BoxDecoration.borderRadius] here — clip defines the curve (avoids corner seams).
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: panelTint,
                    border: Border.all(
                      color: (isDark ? accent : secondary)
                          .withValues(alpha: isDark ? 0.26 : 0.22),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Filter POIs',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? cs.onSurface
                                    : cs.onSurfaceVariant.withValues(alpha: 0.95),
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
                                color: isDark
                                    ? cs.surfaceContainerHighest
                                        .withValues(alpha: 0.55)
                                    : context.lightGlassFieldFill,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(
                        height: 1,
                        color: (isDark ? cs.outline : secondary)
                            .withValues(alpha: isDark ? 0.35 : 0.22),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickFilterButton(
                              label: 'All',
                              onPressed: () {
                                context.read<PoiSearchBloc>().add(
                                      CategoryChanged(_allCatalogKeys()),
                                    );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickFilterButton(
                              label: 'None',
                              onPressed: () {
                                context.read<PoiSearchBloc>().add(
                                      CategoryChanged(<String>[]),
                                    );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: categories.isEmpty
                            ? Center(
                                child: Text(
                                  hideZeroCountCategories
                                      ? 'No POIs in this area for the current categories.'
                                      : 'No categories.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
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
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickFilterButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _QuickFilterButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark
          ? cs.surfaceContainerHighest.withValues(alpha: 0.55)
          : context.lightGlassFieldFill,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ),
      ),
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final def = PoiCategoryCatalog.definitionForUiKey(catKey);
    // [counts] tam bbox/alan listesinden (kategori filtresinden bağımsız).
    final displayCount = counts[catKey] ?? 0;
    final isOn = selected.contains(catKey);
    final color =
        def?.ringColor ?? Theme.of(context).colorScheme.primary;
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
            color: isOn ? color.withValues(alpha: 0.10) : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: isOn ? 0.18 : 0.06),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: isOn ? color : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isOn ? cs.onSurface : cs.onSurfaceVariant,
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
                  color: isDark
                      ? cs.surfaceContainerHighest.withValues(alpha: 0.55)
                      : context.lightGlassFieldFill,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$displayCount',
                  style: TextStyle(
                    fontSize: 10,
                    color: isOn ? cs.onSurface : cs.onSurfaceVariant,
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
