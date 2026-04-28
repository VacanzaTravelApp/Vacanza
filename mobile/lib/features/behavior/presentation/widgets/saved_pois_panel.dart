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
    final isLight = !isDark;
    final accent = context.mapControlAccent;
    final gradientColors = context.mapControlActiveGradientColors;
    const radius = 20.0;

    return SizedBox(
      width: 268,
      height: 430,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: isLight
              ? const [
                  BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
                  BoxShadow(color: Color(0x0E000000), blurRadius: 28, offset: Offset(0, 10)),
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
              child: BlocBuilder<SavedPoisCubit, SavedPoisState>(
                builder: (context, state) {
                  final count = state.items.length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(
                        count: count,
                        accent: accent,
                        gradientColors: gradientColors,
                        isDark: isDark,
                        onClose: onClose,
                      ),
                      const SizedBox(height: 10),
                      Divider(
                        height: 1,
                        thickness: 0.8,
                        color: isLight
                            ? const Color(0xFFE2E8F0)
                            : cs.outline.withValues(alpha: 0.30),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: state.isLoading
                            ? Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: accent,
                                  ),
                                ),
                              )
                            : count == 0
                                ? _EmptyState(
                                    accent: accent,
                                    gradientColors: gradientColors,
                                  )
                                : ListView.separated(
                                    padding: EdgeInsets.zero,
                                    itemCount: count,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, i) {
                                      final poi = state.items[i];
                                      return _SavedPoiTile(
                                        poi: poi,
                                        gradientColors: gradientColors,
                                        onFlyTo: () {
                                          if (!poi.hasCoords) return;
                                          onFlyTo(poi.latitude!, poi.longitude!);
                                        },
                                        onRemove: () =>
                                            context.read<SavedPoisCubit>().remove(poi),
                                      );
                                    },
                                  ),
                      ),
                      if (!state.isLoading && count > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isLight
                                ? const Color(0xFFF0F4F8)
                                : cs.surfaceContainerHighest.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count place${count == 1 ? '' : 's'} saved',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.count,
    required this.accent,
    required this.gradientColors,
    required this.isDark,
    required this.onClose,
  });

  final int count;
  final Color accent;
  final List<Color> gradientColors;
  final bool isDark;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = !isDark;

    return Row(
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
          child: const Icon(Icons.favorite_rounded, size: 15, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              Text(
                'Saved Places',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 8),
                _CountPill(count: count, gradientColors: gradientColors),
              ],
            ],
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
                  : cs.surfaceContainerHighest.withValues(alpha: 0.55),
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
            child: Icon(Icons.close_rounded, size: 15, color: cs.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count, required this.gradientColors});

  final int count;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.accent, required this.gradientColors});

  final Color accent;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors
                      .map((c) => c.withValues(alpha: 0.14))
                      .toList(),
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.28),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.favorite_outline_rounded,
                size: 22,
                color: accent,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No saved places yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
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
    required this.gradientColors,
    required this.onFlyTo,
    required this.onRemove,
  });

  final SavedPoi poi;
  final List<Color> gradientColors;
  final VoidCallback onFlyTo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLight = !isDark;
    final accent = context.mapControlAccent;
    final hasCoords = poi.hasCoords;
    final date = _formatDate(poi.updatedAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasCoords ? onFlyTo : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isLight
                ? Colors.white
                : cs.surfaceContainerHighest.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLight
                  ? const Color(0xFFE8EEF4)
                  : accent.withValues(alpha: 0.14),
              width: 1.0,
            ),
            boxShadow: isLight
                ? const [
                    BoxShadow(
                      color: Color(0x07000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.40),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
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
                              style: TextStyle(
                                fontSize: 10.5,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        if (date.isNotEmpty) ...[
                          if ((poi.category ?? '').trim().isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '•',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (hasCoords)
                Icon(
                  Icons.place_rounded,
                  size: 16,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                ),
              const SizedBox(width: 4),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isLight
                        ? Colors.white
                        : cs.surface.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isLight
                          ? const Color(0xFFE2E8F0)
                          : accent.withValues(alpha: 0.16),
                      width: 1.0,
                    ),
                    boxShadow: isLight
                        ? const [
                            BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 15,
                    color: cs.onSurfaceVariant,
                  ),
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final m = (dt.month >= 1 && dt.month <= 12) ? months[dt.month - 1] : '';
    if (m.isEmpty) return '';
    return '$m ${dt.day}';
  }
}
