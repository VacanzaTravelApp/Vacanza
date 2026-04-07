import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../../checkin/presentation/bloc/location_bloc.dart';
import '../../../../../checkin/presentation/bloc/location_state.dart';
import '../../../../../poi_search/data/models/poi.dart';
import 'package:mobile/core/theme/app_theme.dart';

import '../../../../../poi_search/data/models/poi_category_catalog.dart';
import '../../../../../behavior/domain/feedback_poi_ref.dart';
import '../../../../../behavior/presentation/widgets/poi_favorite_heart_button.dart';
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
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final cs = theme.colorScheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    poi.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: cs.onSurface,
                        ) ??
                        TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: cs.onSurface,
                        ),
                  ),
                ),
                PoiFavoriteHeartButton(
                  ref: FeedbackPoiRef.fromPoi(poi),
                  iconSize: 26,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              categoryLabel,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant,
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: _MapAccentCtaButton(
                enabled: _canFlyTo(poi),
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

class _MapAccentCtaButton extends StatelessWidget {
  const _MapAccentCtaButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gradient = LinearGradient(
      colors: context.mapControlActiveGradientColors,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: Ink(
            decoration: BoxDecoration(
              gradient: enabled ? gradient : null,
              color: enabled ? null : cs.surfaceContainerHighest,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 20,
                    color: enabled ? Colors.white : cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Show on map',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: enabled ? Colors.white : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    final cs = Theme.of(context).colorScheme;
    final hasFix =
        locationState.latitude != null &&
        locationState.longitude != null &&
        locationState.latitude != 0.0 &&
        locationState.longitude != 0.0;

    if (!hasFix || distanceMeters == null) {
      return Row(
        children: [
          Icon(
            Icons.my_location_outlined,
            size: 20,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Distance unavailable (turn on location)',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(Icons.near_me_outlined, size: 20, color: cs.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${_formatDistance(distanceMeters!)} from you',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
