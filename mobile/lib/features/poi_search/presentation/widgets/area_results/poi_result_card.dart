import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

import 'package:mobile/features/behavior/domain/feedback_poi_ref.dart';
import 'package:mobile/features/behavior/presentation/widgets/poi_favorite_heart_button.dart';

import '../../../data/models/poi.dart';
import '../../../data/models/poi_category_catalog.dart';

class PoiResultCard extends StatelessWidget {
  final Poi poi;
  final VoidCallback? onTap;

  const PoiResultCard({
    super.key,
    required this.poi,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = context.mapControlAccent;
    final title = PoiCategoryCatalog.safePoiTitle(
      name: poi.name,
      rawCategory: poi.category,
    );
    final categoryLabel =
        PoiCategoryCatalog.labelForRawCategory(poi.category) ??
            (poi.category.trim().isEmpty ? 'place' : poi.category.trim());

    final radius = BorderRadius.circular(16);
    return Material(
      // IMPORTANT: clip the ripple + hitbox to the rounded shape,
      // otherwise the rectangular tap area can show as a "grey gap".
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: isLight
            ? accent.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isLight
                ? context.lightGlassFieldFill
                : t.pillSurface.withValues(alpha: 0.88),
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: t.overlayScrim.withValues(alpha: isLight ? 0.18 : 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              // Thin secondary/accent frame, subtle in both modes.
              color: isLight
                  ? accent.withValues(alpha: 0.22)
                  : accent.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              _CategoryDot(rawCategory: poi.category),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: t.textMain,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      categoryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: t.textSub,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              PoiFavoriteHeartButton(
                ref: FeedbackPoiRef.fromPoi(poi),
                iconSize: 22,
                padding: EdgeInsets.zero,
              ),

              const SizedBox(width: 4),

              Text(
                '→',
                style: TextStyle(
                  fontSize: 18,
                  color: t.textSub.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryDot extends StatelessWidget {
  final String rawCategory;
  const _CategoryDot({required this.rawCategory});

  @override
  Widget build(BuildContext context) {
    final def = PoiCategoryCatalog.poiCategoryForRaw(rawCategory);
    final color = def?.ringColor ?? Theme.of(context).colorScheme.primary;
    final icon = def?.iconData ?? Icons.place_rounded;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 20,
        color: color,
      ),
    );
  }
}