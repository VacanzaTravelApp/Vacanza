// ======================= area_results_bottom_sheet.dart =======================
// lib/features/poi_search/presentation/widgets/area_results/area_results_bottom_sheet.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/vacanza_gradient_button.dart';
import 'package:mobile/core/theme/vacanza_tokens.dart';

import '../../../data/models/poi.dart';
import '../../../data/models/poi_category_catalog.dart';
import 'area_results_header.dart';
import 'area_results_list.dart';

class AreaResultsSheet extends StatelessWidget {
  final bool isVisible;

  /// Backend toplam count (tüm seçili kategoriler için)
  final int count;

  /// Backend'ten gelen sonuçlar
  final List<Poi> pois;

  /// Backend counts (selectedCategories kapsamındaki toplam)
  /// (UI’da sayı göstermiyoruz; sadece ordering/guard için kalabilir)
  final Map<String, int> countsByCategory;

  /// Filter panelde seçili kategoriler (chip bar buradan türetilir)
  final List<String> selectedCategories;

  /// null => All (UI filter)
  final String? activeChipKey;

  /// Chip değişince sadece UI filter güncellenir (backend request yok)
  final ValueChanged<String?> onChipSelected;

  /// X’e basınca: selection temizlenip viewport’a dönülecek (A senaryosu)
  final VoidCallback onClose;

  /// POI tap: open same detail UI as marker tap.
  final ValueChanged<Poi>? onPoiTap;

  /// Alan çizimi (user selection) sonrası: 0 POI’lı chip’leri gösterme.
  /// Viewport / genel harita akışında `false` — tüm seçili kategoriler chip’te kalır.
  final bool hideZeroCountCategories;

  /// Drawn-area flow: show primary action to generate an AI route from the polygon.
  final bool showCreateRouteFromArea;

  /// While the route is being generated (shared loading state).
  final bool isCreatingRoute;

  final VoidCallback? onCreateRouteFromArea;

  /// Mapbox SSE: kategoriler gelirken ince yükleme çubuğu.
  final bool showStreamLoadingMore;

  const AreaResultsSheet({
    super.key,
    required this.isVisible,
    required this.count,
    required this.pois,
    required this.countsByCategory,
    required this.selectedCategories,
    required this.activeChipKey,
    required this.onChipSelected,
    required this.onClose,
    this.onPoiTap,
    this.hideZeroCountCategories = false,
    this.showCreateRouteFromArea = false,
    this.isCreatingRoute = false,
    this.onCreateRouteFromArea,
    this.showStreamLoadingMore = false,
  });

  String _labelFor(String key) {
    final def = PoiCategoryCatalog.definitionForUiKey(key);
    if (def != null) return def.label;
    if (key.isEmpty) return key;
    return key[0].toUpperCase() + key.substring(1);
  }

  IconData _iconFor(String key) {
    return PoiCategoryCatalog.definitionForUiKey(key)?.iconData ??
        Icons.place_rounded;
  }

  Color _colorFor(BuildContext context, String key) {
    return PoiCategoryCatalog.definitionForUiKey(key)?.ringColor ??
        Theme.of(context).colorScheme.primary;
  }

  int _countFor(String key) => countsByCategory[key] ?? 0;

  /// Seçili kategoriler + sıra (count filtresi yok).
  List<String> _normalizedSelectedCategoriesAll() {
    final set = <String>{};
    for (final c in selectedCategories) {
      final k = c.trim().toLowerCase();
      if (k.isNotEmpty) set.add(k);
    }

    if (set.isEmpty && countsByCategory.isNotEmpty) {
      set.addAll(countsByCategory.keys.map((e) => e.trim().toLowerCase()));
    }

    final baseOrder = PoiCategoryCatalog.all
        .map((e) => e.key)
        .toList(growable: false);
    final ordered = <String>[];

    for (final k in baseOrder) {
      if (set.contains(k)) ordered.add(k);
    }

    final extras = set.where((k) => !baseOrder.contains(k)).toList()..sort();
    ordered.addAll(extras);

    return ordered;
  }

  /// Sadece en az 1 POI olan kategoriler (alan çizimi akışı).
  List<String> _normalizedSelectedCategoriesPositiveOnly() {
    final set = <String>{};
    for (final c in selectedCategories) {
      final k = c.trim().toLowerCase();
      if (k.isNotEmpty && _countFor(k) > 0) set.add(k);
    }

    if (set.isEmpty && countsByCategory.isNotEmpty) {
      for (final e in countsByCategory.entries) {
        final k = e.key.trim().toLowerCase();
        if (k.isNotEmpty && _countFor(k) > 0) set.add(k);
      }
    }

    final baseOrder = PoiCategoryCatalog.all
        .map((e) => e.key)
        .toList(growable: false);
    final ordered = <String>[];

    for (final k in baseOrder) {
      if (set.contains(k) && _countFor(k) > 0) ordered.add(k);
    }

    final extras =
        set.where((k) => !baseOrder.contains(k) && _countFor(k) > 0).toList()
          ..sort();
    ordered.addAll(extras);

    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final t = context.vacanzaTokens;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    final chips =
        hideZeroCountCategories
            ? _normalizedSelectedCategoriesPositiveOnly()
            : _normalizedSelectedCategoriesAll();

    final rawActive = activeChipKey?.trim().toLowerCase();
    final String? activeKey;
    if (hideZeroCountCategories) {
      activeKey =
          (rawActive != null &&
                  rawActive.isNotEmpty &&
                  chips.contains(rawActive))
              ? rawActive
              : null;
    } else {
      activeKey =
          (rawActive != null && rawActive.isNotEmpty) ? rawActive : null;
    }
    final allActive = activeKey == null || activeKey.isEmpty;

    // ✅ UI filtreleme: backend'e gitmeden mevcut pois içinde gez
    final List<Poi> visiblePois =
        allActive
            ? pois
            : pois.where((p) {
              final ui = PoiCategoryCatalog.poiCategoryForRaw(p.category)?.key;
              return ui == activeKey;
            }).toList();

    final visibleCount = visiblePois.length;

    final screenH = MediaQuery.sizeOf(context).height;
    final sheetHeight = (screenH * 0.52).clamp(300.0, 560.0);

    final sheet = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isLight ? 14 : 14,
          sigmaY: isLight ? 14 : 14,
        ),
        child: SizedBox(
          height: sheetHeight,
          child: Container(
            decoration: BoxDecoration(
              // Night theme: keep the glass surface that you liked.
              // Day theme: also glass, but neutral (avoid bluish tint).
              color: isLight ? context.lightGlassPanelColor : t.glassBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color:
                    isLight
                        ? context.mapControlAccent.withValues(alpha: 0.22)
                        : t.cardBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isLight ? cs.shadow : t.overlayScrim).withValues(
                    alpha: isLight ? 0.12 : 0.35,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // handle bar
                const SizedBox(height: 10),
                Container(
                  width: 46,
                  height: 4,
                  decoration: BoxDecoration(
                    color: t.textSub.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 10),

                AreaResultsHeader(
                  title: 'Results in Your Area',
                  subtitle:
                      allActive
                          ? '$count places found'
                          : '$visibleCount places found',
                  onClose: onClose,
                ),

                // ✅ CHIP BAR (NO COUNTS)
                _ChipBar(
                  chips: chips,
                  activeChipKey: allActive ? null : activeKey,
                  labelFor: _labelFor,
                  iconFor: _iconFor,
                  colorFor: (key) => _colorFor(context, key),
                  onChipSelected: onChipSelected,
                ),

                if (showStreamLoadingMore) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Daha fazla kategori yükleniyor…',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: t.textSub,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            backgroundColor: t.cardBorder,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                Divider(height: 1, color: t.cardBorder),

                Expanded(
                  child: AreaResultsList(pois: visiblePois, onPoiTap: onPoiTap),
                ),

                if (showCreateRouteFromArea &&
                    onCreateRouteFromArea != null) ...[
                  Divider(height: 1, color: t.cardBorder),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    child: VacanzaGradientButton(
                      label: 'Create a route',
                      onPressed:
                          (isCreatingRoute ? null : onCreateRouteFromArea),
                      enabled: !isCreatingRoute,
                      loading: isCreatingRoute,
                      minHeight: 50,
                      borderRadius: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return Material(color: Colors.transparent, child: sheet);
  }
}

class _ChipBar extends StatelessWidget {
  final List<String> chips;

  /// null => All
  final String? activeChipKey;

  final String Function(String) labelFor;
  final IconData Function(String) iconFor;
  final Color Function(String) colorFor;

  final ValueChanged<String?> onChipSelected;

  const _ChipBar({
    required this.chips,
    required this.activeChipKey,
    required this.labelFor,
    required this.iconFor,
    required this.colorFor,
    required this.onChipSelected,
  });

  @override
  Widget build(BuildContext context) {
    final allSelected = activeChipKey == null;
    final t = context.vacanzaTokens;
    final accent = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
        children: [
          _buildChip(
            t: t,
            label: 'All',
            icon: Icons.apps_rounded,
            color: accent,
            selected: allSelected,
            onTap: () => onChipSelected(null),
          ),
          const SizedBox(width: 8),

          ...chips.map((key) {
            final k = key.trim().toLowerCase();
            final selected = !allSelected && activeChipKey == k;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(
                t: t,
                label: labelFor(k),
                icon: iconFor(k),
                color: colorFor(k),
                selected: selected,
                onTap: () => onChipSelected(k),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip({
    required VacanzaTokens t,
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : t.pillSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.45) : t.cardBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? color : t.textSub),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? t.textMain : t.textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
