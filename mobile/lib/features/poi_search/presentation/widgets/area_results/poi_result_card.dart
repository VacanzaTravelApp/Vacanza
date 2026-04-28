import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/vacanza_tokens.dart';

import 'package:mobile/features/behavior/domain/feedback_poi_ref.dart';
import 'package:mobile/features/behavior/presentation/widgets/poi_favorite_heart_button.dart';

import '../../../data/models/poi.dart';
import '../../../data/models/poi_category_catalog.dart';

class PoiResultCard extends StatelessWidget {
  final Poi poi;
  final VoidCallback? onTap;
  final int? index;

  const PoiResultCard({
    super.key,
    required this.poi,
    this.onTap,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = context.mapControlAccent;

    final def = PoiCategoryCatalog.poiCategoryForRaw(poi.category);
    final categoryColor = def?.ringColor ?? accent;

    final title = PoiCategoryCatalog.safePoiTitle(
      name: poi.name,
      rawCategory: poi.category,
    );
    final categoryLabel =
        PoiCategoryCatalog.labelForRawCategory(poi.category) ??
            (poi.category.trim().isEmpty ? 'place' : poi.category.trim());

    final cardBg = isLight ? context.lightGlassFieldFill : t.cardBg;
    final outerRadius = BorderRadius.circular(16);

    final cardCore = Material(
      color: Colors.transparent,
      borderRadius: outerRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: categoryColor.withValues(alpha: isLight ? 0.08 : 0.12),
        highlightColor: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(color: cardBg),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left category accent stripe
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        categoryColor,
                        categoryColor.withValues(alpha: 0.30),
                      ],
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 13, 12, 13),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _CategoryIcon(
                          def: def,
                          accent: accent,
                          isLight: isLight,
                          index: index,
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  letterSpacing: -0.2,
                                  color: t.textMain,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      categoryLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: t.textSub,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (_priceText(poi.priceLevel)
                                      .isNotEmpty) ...[
                                    Text(
                                      ' · ',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: t.textSub.withValues(alpha: 0.45),
                                      ),
                                    ),
                                    Text(
                                      _priceText(poi.priceLevel!),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: t.textSub,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (poi.rating != null) ...[
                                const SizedBox(height: 4),
                                _RatingRow(
                                  rating: poi.rating!,
                                  color: categoryColor,
                                  t: t,
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(width: 4),

                        PoiFavoriteHeartButton(
                          ref: FeedbackPoiRef.fromPoi(poi),
                          iconSize: 20,
                          padding: EdgeInsets.zero,
                        ),

                        const SizedBox(width: 2),

                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: t.textSub.withValues(alpha: 0.45),
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

    if (isLight) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: outerRadius,
          border: Border.all(
            color: categoryColor.withValues(alpha: 0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: cardCore,
      );
    }

    // Dark mode: gradient outline border (category color → neutral → vivid blue)
    return Container(
      decoration: BoxDecoration(
        borderRadius: outerRadius,
        boxShadow: [
          BoxShadow(
            color: categoryColor.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(1.0),
        decoration: BoxDecoration(
          borderRadius: outerRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              categoryColor.withValues(alpha: 0.45),
              t.cardBorder.withValues(alpha: 0.20),
              t.vividBlue.withValues(alpha: 0.15),
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: cardCore,
        ),
      ),
    );
  }

  static String _priceText(String? level) {
    if (level == null || level.trim().isEmpty) return '';
    final l = level.toLowerCase();
    if (l.contains('free')) return 'Free';
    if (l.contains('very_expensive') || l == '4') return '\$\$\$\$';
    if (l.contains('expensive') || l == '3') return '\$\$\$';
    if (l.contains('moderate') || l == '2') return '\$\$';
    if (l.contains('inexpensive') || l == '1') return '\$';
    if (l.startsWith('\$')) return level.trim();
    return '';
  }
}

class _CategoryIcon extends StatelessWidget {
  final PoiCategoryDefinition? def;
  final Color accent;
  final bool isLight;
  final int? index;

  const _CategoryIcon({
    required this.def,
    required this.accent,
    required this.isLight,
    this.index,
  });

  @override
  Widget build(BuildContext context) {
    final color = def?.ringColor ?? accent;
    final icon = def?.iconData ?? Icons.place_rounded;

    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isLight ? 0.11 : 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: isLight ? 0.22 : 0.32),
                width: 1,
              ),
              boxShadow: isLight
                  ? null
                  : [
                      BoxShadow(
                        color: color.withValues(alpha: 0.22),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
            ),
            child: Icon(icon, size: 20, color: color),
          ),

          // Rank badge (top-right corner)
          if (index != null)
            Positioned(
              right: -3,
              top: -3,
              child: Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: isLight ? color : color.withValues(alpha: 0.90),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isLight ? Colors.white : const Color(0xFF13141C),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    index! < 9 ? '${index! + 1}' : '9+',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;
  final Color color;
  final VacanzaTokens t;

  const _RatingRow({
    required this.rating,
    required this.color,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final filled = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 5; i++)
          Icon(
            i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 11,
            color: i < filled
                ? color
                : t.textSub.withValues(alpha: 0.30),
          ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: t.textSub,
          ),
        ),
      ],
    );
  }
}
