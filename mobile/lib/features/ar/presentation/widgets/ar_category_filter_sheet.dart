import 'package:flutter/material.dart';

import 'package:mobile/features/poi_search/data/models/poi_category_catalog.dart';

import '../styles/ar_poi_style.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ArCategoryFilterSheet._allCatalogKeys();
    final counts = widget.countsByCategory;

    // Dark: glassy indigo panel. Light: clean white card.
    final bgColor = isDark ? const Color(0xF21C1C40) : Colors.white;
    final handleColor =
        isDark ? const Color(0x40FFFFFF) : const Color(0x33000000);
    final iconColor =
        isDark ? const Color(0xCCFFFFFF) : const Color(0xCC000000);
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final dividerColor =
        isDark ? const Color(0x26FFFFFF) : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? const Color(0x33FFFFFF) : const Color(0xFFE5E7EB),
          width: isDark ? 0.8 : 1.0,
        ),
        boxShadow: isDark
            ? null
            : [
                const BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 24,
                  offset: Offset(0, -6),
                ),
              ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Filter Places',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0x26FFFFFF)
                        : const Color(0xFFF3F4F6),
                    border: Border.all(
                      color: isDark
                          ? const Color(0x26FFFFFF)
                          : const Color(0xFFE5E7EB),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // All / None
          Row(
            children: [
              Expanded(
                child: _QuickFilterPill(
                  label: 'All',
                  isDark: isDark,
                  onPressed: _selectAll,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickFilterPill(
                  label: 'None',
                  isDark: isDark,
                  onPressed: _clearAll,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: isDark ? 0.6 : 1.0, color: dividerColor),
          const SizedBox(height: 4),
          // Category list
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final key in categories)
                    _CategoryRow(
                      catKey: key,
                      counts: counts,
                      selected: _selected,
                      isDark: isDark,
                      onToggle: _toggle,
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickFilterPill extends StatelessWidget {
  const _QuickFilterPill({
    required this.label,
    required this.isDark,
    required this.onPressed,
  });

  final String label;
  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isDark ? const Color(0x1AFFFFFF) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isDark ? const Color(0x26FFFFFF) : const Color(0xFFE5E7EB),
            width: 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF374151),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.catKey,
    required this.counts,
    required this.selected,
    required this.isDark,
    required this.onToggle,
  });

  final String catKey;
  final Map<String, int> counts;
  final Set<String> selected;
  final bool isDark;
  final void Function(String key) onToggle;

  @override
  Widget build(BuildContext context) {
    final def = PoiCategoryCatalog.definitionForUiKey(catKey);
    final glowColor = arPoiRingColorForCategory(catKey);
    final icon = arPoiIconForCategory(catKey);
    final label = def?.label ?? catKey;
    final displayCount = counts[catKey] ?? 0;
    final isOn = selected.contains(catKey);

    // Light mode: clean card rows with clear contrast
    Color rowBg;
    Color rowBorder;
    Color textColor;
    Color orbBg;
    Color orbBorder;
    Color iconColor;
    Color badgeBg;
    Color badgeBorder;
    Color badgeText;

    if (isDark) {
      rowBg = isOn ? glowColor.withValues(alpha: 0.10) : Colors.transparent;
      rowBorder = isOn
          ? glowColor.withValues(alpha: 0.30)
          : const Color(0x1AFFFFFF);
      textColor = isOn ? Colors.white : const Color(0x99FFFFFF);
      orbBg = glowColor.withValues(alpha: isOn ? 0.20 : 0.07);
      orbBorder = glowColor.withValues(alpha: isOn ? 0.50 : 0.20);
      iconColor = isOn ? glowColor : const Color(0x66FFFFFF);
      badgeBg = isOn
          ? glowColor.withValues(alpha: 0.15)
          : const Color(0x1AFFFFFF);
      badgeBorder = isOn
          ? glowColor.withValues(alpha: 0.30)
          : const Color(0x1AFFFFFF);
      badgeText = isOn ? glowColor : const Color(0x66FFFFFF);
    } else {
      rowBg = isOn
          ? glowColor.withValues(alpha: 0.08)
          : const Color(0xFFFAFAFA);
      rowBorder = isOn
          ? glowColor.withValues(alpha: 0.40)
          : const Color(0xFFE5E7EB);
      textColor = isOn ? const Color(0xFF111827) : const Color(0xFF374151);
      orbBg = glowColor.withValues(alpha: isOn ? 0.18 : 0.10);
      orbBorder = glowColor.withValues(alpha: isOn ? 0.60 : 0.35);
      iconColor = glowColor.withValues(alpha: isOn ? 1.0 : 0.70);
      badgeBg = isOn
          ? glowColor.withValues(alpha: 0.12)
          : const Color(0xFFEEEEEE);
      badgeBorder = isOn
          ? glowColor.withValues(alpha: 0.30)
          : const Color(0xFFDDDDDD);
      badgeText = isOn ? glowColor : const Color(0xFF888888);
    }

    return GestureDetector(
      onTap: () => onToggle(catKey),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: rowBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: rowBorder,
            width: isOn ? 1.0 : 0.8,
          ),
          boxShadow: isOn && !isDark
              ? [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.12),
                    blurRadius: 8,
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
                color: orbBg,
                border: Border.all(color: orbBorder, width: 0.8),
                boxShadow: isOn
                    ? [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.25),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, size: 13, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                  fontWeight: isOn ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: badgeBorder, width: 0.6),
              ),
              child: Text(
                '$displayCount',
                style: TextStyle(
                  fontSize: 10,
                  color: badgeText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
        padding: EdgeInsets.fromLTRB(0, 0, 0, inset),
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
