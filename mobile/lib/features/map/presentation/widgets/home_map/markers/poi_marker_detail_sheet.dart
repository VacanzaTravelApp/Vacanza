import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../../checkin/presentation/bloc/location_bloc.dart';
import '../../../../../checkin/presentation/bloc/location_state.dart';
import '../../../../../poi_search/data/models/poi.dart';
import '../../../../../poi_search/data/models/poi_category_catalog.dart';
import '../../../bloc/map_bloc.dart';
import '../../../bloc/map_event.dart';

/// Bottom sheet shown when the user taps a POI map marker.
void showPoiMarkerDetailSheet(BuildContext context, Poi poi) {
  // Resolve blocs from the caller context — modal route context does not see them.
  final mapBloc = context.read<MapBloc>();
  final loc = context.read<LocationBloc>().state;
  final categoryLabel =
      PoiCategoryCatalog.labelForRawCategory(poi.category) ?? poi.category;

  double? distanceMeters;
  if (loc.latitude != null &&
      loc.longitude != null &&
      loc.latitude != 0.0 &&
      loc.longitude != 0.0) {
    distanceMeters = Geolocator.distanceBetween(
      loc.latitude!,
      loc.longitude!,
      poi.latitude,
      poi.longitude,
    );
  }

  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poi.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              categoryLabel,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _DistanceRow(
              distanceMeters: distanceMeters,
              locationState: loc,
            ),
            if (poi.rating != null && poi.rating! > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.star_rounded, size: 20, color: Colors.amber.shade700),
                  const SizedBox(width: 6),
                  Text(
                    poi.rating!.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canFlyTo(poi)
                    ? () {
                        Navigator.of(ctx).pop();
                        mapBloc.add(
                          FlyToPoiRequested(
                            latitude: poi.latitude,
                            longitude: poi.longitude,
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.map_outlined, size: 20),
                label: const Text('Show on map'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

bool _canFlyTo(Poi poi) {
  return !(poi.latitude == 0.0 && poi.longitude == 0.0);
}

class _DistanceRow extends StatelessWidget {
  const _DistanceRow({
    required this.distanceMeters,
    required this.locationState,
  });

  final double? distanceMeters;
  final LocationState locationState;

  static String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final hasFix =
        locationState.latitude != null &&
        locationState.longitude != null &&
        locationState.latitude != 0.0 &&
        locationState.longitude != 0.0;

    if (!hasFix || distanceMeters == null) {
      return Row(
        children: [
          Icon(Icons.my_location_outlined, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Distance unavailable (turn on location)',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(Icons.near_me_outlined, size: 20, color: Colors.blue.shade700),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${_formatDistance(distanceMeters!)} from you',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
