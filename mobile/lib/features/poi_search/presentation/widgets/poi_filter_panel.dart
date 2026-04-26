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
/// viewport'ta tüm kategoriler listelenir; 0 gizleme sadece çizim sonrası için.
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
        final isLight = !isDark;
        final accent = context.mapControlAccent;
        final gradientColors = context.mapControlActiveGradientColors;
        final counts = state.countsByCategory;
        final allKeys = _allCatalogKeys();
        final categories = hideZeroCountCategories
            ? allKeys
                .where((key) => (counts[key] ?? 0) > 0)
                .toList(growable: false)
            : allKeys;
        final selected = state.selectedCategories.toSet();
        const radius = 20.0;

        return SizedBox(
          width: 210,
          height: 420,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: isLight
                  ? const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Color(0x0E000000),
                        blurRadius: 28,
                        offset: Offset(0, 10),
                      ),
                      BoxShadow(color: Color(0x05000000), blurRadius: 1),
                    ]
                  : [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.28),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              clipBehavior: Clip.antiAlias,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: isLight ? 14 : 0,
                  sigmaY: isLight ? 14 : 0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isLight
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, Color(0xFFF8FAFC)],
                          )
                        : null,
                    color: isDark ? cs.surface.withValues(alpha: 0.88) : null,
                    border: Border.all(
                      color: isLight
                          ? const Color(0xFFE2E8F0)
                          : accent.withValues(alpha: 0.26),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header ───────────────────────────────────
                      Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: gradientColors,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.32),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.filter_alt_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Filter POIs',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: onClose,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isLight
                                    ? Colors.white
                                    : cs.surfaceContainerHighest
                                        .withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isLight
                                      ? const Color(0xFFE2E8F0)
                                      : accent.withValues(alpha: 0.22),
                                  width: 1.2,
                                ),
                                boxShadow: isLight
                                    ? const [
                                        BoxShadow(
                                          color: Color(0x08000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 15,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(
                        height: 1,
                        thickness: 0.8,
                        color: isLight
                            ? const Color(0xFFE2E8F0)
                            : cs.outline.withValues(alpha: 0.30),
                      ),
                      const SizedBox(height: 10),
                      // ── Quick filter buttons ─────────────────────
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
                      const SizedBox(height: 10),
                      // ── Category list ────────────────────────────
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
    final isLight = !isDark;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isLight
                ? Colors.white
                : cs.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isLight
                  ? const Color(0xFFE2E8F0)
                  : cs.outline.withValues(alpha: 0.35),
              width: 1.0,
            ),
            boxShadow: isLight
                ? const [
                    BoxShadow(
                      color: Color(0x07000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
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
    final isLight = !isDark;
    final def = PoiCategoryCatalog.definitionForUiKey(catKey);
    final isOn = selected.contains(catKey);
    final color = def?.ringColor ?? cs.primary;
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isOn
                ? (isLight ? Colors.white : color.withValues(alpha: 0.10))
                : Colors.transparent,
            border: isOn
                ? Border.all(
                    color: color.withValues(alpha: isLight ? 0.28 : 0.20),
                    width: 1.0,
                  )
                : null,
            boxShadow: isOn && isLight
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.10),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                    const BoxShadow(
                      color: Color(0x07000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: isOn ? 0.90 : 0.08),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: isOn ? Colors.white : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isOn ? cs.onSurface : cs.onSurfaceVariant,
                    fontWeight: isOn ? FontWeight.w600 : FontWeight.w500,
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
