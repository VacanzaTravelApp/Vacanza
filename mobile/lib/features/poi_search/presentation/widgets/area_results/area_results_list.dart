import 'package:flutter/material.dart';

import '../../../data/models/poi.dart';
import 'poi_result_card.dart';

class AreaResultsList extends StatelessWidget {
  final List<Poi> pois;

  const AreaResultsList({
    super.key,
    required this.pois,
  });

  @override
  Widget build(BuildContext context) {
    if (pois.isEmpty) {
      return Center(
        child: Text(
          'No results.',
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.55),
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
        return PoiResultCard(poi: pois[index]);
      },
    );
  }
}