import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

import '../../../data/models/poi.dart';
import 'poi_result_card.dart';

class AreaResultsList extends StatelessWidget {
  final List<Poi> pois;
  final ValueChanged<Poi>? onPoiTap;

  const AreaResultsList({
    super.key,
    required this.pois,
    this.onPoiTap,
  });

  @override
  Widget build(BuildContext context) {
    if (pois.isEmpty) return _EmptyState();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      itemCount: pois.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final poi = pois[index];
        return PoiResultCard(
          poi: poi,
          index: index,
          onTap: onPoiTap == null ? null : () => onPoiTap!(poi),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final accent = context.mapControlAccent;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isLight ? 0.08 : 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: isLight ? 0.18 : 0.25),
                  width: 1,
                ),
                boxShadow: isLight
                    ? null
                    : [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.15),
                          blurRadius: 16,
                        ),
                      ],
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 30,
                color: accent.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No places found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: t.textMain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different area or\nadjust the category filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: t.textSub,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
