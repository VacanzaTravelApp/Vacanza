import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';

import '../../domain/saved_poi.dart';
import '../cubit/saved_pois_cubit.dart';

class SavedPoisPanel extends StatelessWidget {
  const SavedPoisPanel({
    super.key,
    required this.onClose,
    required this.onFlyTo,
  });

  final VoidCallback onClose;
  final void Function(double lat, double lon) onFlyTo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.mapControlAccent;
    const radius = 18.0;
    final panelTint = isDark ? cs.surface.withValues(alpha: 0.88) : context.lightGlassPanelColor;

    return SizedBox(
      width: 260,
      height: 420,
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
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: panelTint,
                border: Border.all(
                  color: accent.withValues(alpha: isDark ? 0.26 : 0.18),
                ),
              ),
              child: BlocBuilder<SavedPoisCubit, SavedPoisState>(
                builder: (context, state) {
                  final count = state.items.length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.favorite_rounded, size: 16, color: accent),
                                const SizedBox(width: 8),
                                Text(
                                  'Saved Places',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? cs.onSurface : cs.onSurfaceVariant.withValues(alpha: 0.95),
                                  ),
                                ),
                                if (count > 0) ...[
                                  const SizedBox(width: 8),
                                  _CountPill(count: count),
                                ],
                              ],
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
                                    ? cs.surfaceContainerHighest.withValues(alpha: 0.55)
                                    : context.lightGlassFieldFill,
                                shape: BoxShape.circle,
                                border: Border.all(color: accent.withValues(alpha: 0.22)),
                              ),
                              child: Icon(Icons.close_rounded, size: 16, color: cs.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Divider(
                        height: 1,
                        color: (isDark ? cs.outline : cs.secondary).withValues(alpha: isDark ? 0.35 : 0.22),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: state.isLoading
                            ? Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                                ),
                              )
                            : count == 0
                                ? _EmptyState(accent: accent)
                                : ListView.separated(
                                    itemCount: count,
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (context, i) {
                                      final poi = state.items[i];
                                      return _SavedPoiTile(
                                        poi: poi,
                                        onFlyTo: () {
                                          if (!poi.hasCoords) return;
                                          onFlyTo(poi.latitude!, poi.longitude!);
                                        },
                                        onRemove: () => context.read<SavedPoisCubit>().remove(poi),
                                      );
                                    },
                                  ),
                      ),
                      if (!state.isLoading && count > 0) ...[
                        const SizedBox(height: 10),
                        Text(
                          '$count place${count == 1 ? '' : 's'} saved',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.mapControlAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isDark ? cs.onSurface : cs.onSurfaceVariant.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_outline_rounded, size: 22, color: accent.withValues(alpha: 0.85)),
            const SizedBox(height: 10),
            Text(
              'No saved places yet',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              'Like a place from the map or your route to save it here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedPoiTile extends StatelessWidget {
  const _SavedPoiTile({
    required this.poi,
    required this.onFlyTo,
    required this.onRemove,
  });

  final SavedPoi poi;
  final VoidCallback onFlyTo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.mapControlAccent;

    final date = _formatDate(poi.updatedAt);
    final hasCoords = poi.hasCoords;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasCoords ? onFlyTo : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? cs.surfaceContainerHighest.withValues(alpha: 0.38) : context.lightGlassFieldFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poi.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.onSurface),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if ((poi.category ?? '').trim().isNotEmpty)
                          Flexible(
                            child: Text(
                              _formatCategory(poi.category),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant),
                            ),
                          ),
                        if (date.isNotEmpty) ...[
                          if ((poi.category ?? '').trim().isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text('•', style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant)),
                            const SizedBox(width: 6),
                          ],
                          Text(date, style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (hasCoords)
                Icon(Icons.place_rounded, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDark ? cs.surface.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.16)),
                  ),
                  child: Icon(Icons.delete_outline_rounded, size: 18, color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatCategory(String? cat) {
    final c = (cat ?? '').trim();
    if (c.isEmpty) return '';
    final spaced = c.replaceAll('_', ' ');
    return spaced
        .split(' ')
        .where((p) => p.trim().isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
        .join(' ');
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final m = (dt.month >= 1 && dt.month <= 12) ? months[dt.month - 1] : '';
    if (m.isEmpty) return '';
    return '$m ${dt.day}';
  }
}

