import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/poi_search/data/models/poi_category_catalog.dart';

/// Ana sayfa [PoiFilterPanel] ile aynı cam panel + satır stilleri.
class ArCategoryFilterSheet extends StatefulWidget {
  const ArCategoryFilterSheet({
    super.key,
    required this.initialSelection,
    required this.countsByCategory,
    required this.onSelectionChanged,
    required this.onClose,
  });

  final Set<String> initialSelection;
  final Map<String, int> countsByCategory;
  final void Function(Set<String> selected) onSelectionChanged;
  final VoidCallback onClose;

  static List<String> _allCatalogKeys() =>
      PoiCategoryCatalog.all.map((e) => e.key).toList(growable: false);

  @override
  State<ArCategoryFilterSheet> createState() => _ArCategoryFilterSheetState();
}

class _ArCategoryFilterSheetState extends State<ArCategoryFilterSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initialSelection);
  }

  void _emit() => widget.onSelectionChanged(Set<String>.from(_selected));

  void _selectAll() {
    setState(() {
      _selected = ArCategoryFilterSheet._allCatalogKeys().toSet();
    });
    _emit();
  }

  void _clearAll() {
    setState(() => _selected.clear());
    _emit();
  }

  void _toggle(String catKey) {
    setState(() {
      if (_selected.contains(catKey)) {
        _selected.remove(catKey);
      } else {
        _selected.add(catKey);
      }
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.mapControlAccent;
    final secondary = cs.secondary;
    final counts = widget.countsByCategory;
    final categories = ArCategoryFilterSheet._allCatalogKeys();

    const radius = 18.0;
    final panelTint = isDark
        ? cs.surface.withValues(alpha: 0.88)
        : context.lightGlassPanelColor;

    return DecoratedBox(
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
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: cs.outline.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
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
                      onTap: widget.onClose,
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
                      child: _ArQuickFilterButton(
                        label: 'All',
                        onPressed: _selectAll,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ArQuickFilterButton(
                        label: 'None',
                        onPressed: _clearAll,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final key in categories)
                          _ArFilterRow(
                            catKey: key,
                            counts: counts,
                            selected: _selected,
                            onToggle: _toggle,
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
    );
  }
}

class _ArQuickFilterButton extends StatelessWidget {
  const _ArQuickFilterButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

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

class _ArFilterRow extends StatelessWidget {
  const _ArFilterRow({
    required this.catKey,
    required this.counts,
    required this.selected,
    required this.onToggle,
  });

  final String catKey;
  final Map<String, int> counts;
  final Set<String> selected;
  final void Function(String key) onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final def = PoiCategoryCatalog.definitionForUiKey(catKey);
    final displayCount = counts[catKey] ?? 0;
    final isOn = selected.contains(catKey);
    final color = def?.ringColor ?? cs.primary;
    final icon = def?.iconData ?? Icons.place_rounded;
    final label = def?.label ?? catKey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onToggle(catKey),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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

Future<void> showArCategoryFilterSheet({
  required BuildContext context,
  required Set<String> initialSelection,
  required Map<String, int> countsByCategory,
  required void Function(Set<String> selected) onSelectionChanged,
}) {
  final maxH = MediaQuery.sizeOf(context).height * 0.72;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final inset = MediaQuery.of(ctx).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + inset),
        child: SizedBox(
          height: maxH,
          child: ArCategoryFilterSheet(
            initialSelection: initialSelection,
            countsByCategory: countsByCategory,
            onSelectionChanged: onSelectionChanged,
            onClose: () => Navigator.of(ctx).pop(),
          ),
        ),
      );
    },
  );
}
