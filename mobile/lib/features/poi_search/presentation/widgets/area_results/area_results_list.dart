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
    if (pois.isEmpty) {
      final t = context.vacanzaTokens;
      return Center(
        child: Text(
          'No results.',
          style: TextStyle(
            color: t.textSub,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      itemCount: pois.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final poi = pois[index];
        return PoiResultCard(
          poi: poi,
          onTap: onPoiTap == null ? null : () => onPoiTap!(poi),
        );
      },
    );
  }
}