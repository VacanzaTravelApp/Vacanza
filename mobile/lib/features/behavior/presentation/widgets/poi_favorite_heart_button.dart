import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';

import '../../domain/feedback_poi_ref.dart';
import '../../domain/poi_feedback_utils.dart';
import '../cubit/favorite_poi_cubit.dart';

/// Heart toggle — same semantics as web [MapPage.jsx] `toggleMapPoiFavorite`.
class PoiFavoriteHeartButton extends StatelessWidget {
  const PoiFavoriteHeartButton({
    super.key,
    required this.ref,
    this.iconSize = 24,
    this.padding = const EdgeInsets.all(4),
    this.tooltipFavorite = 'Save to favorites',
    this.tooltipUnfavorite = 'Remove favorite',
    this.filledColor,
    this.outlineColor,
  });

  final FeedbackPoiRef ref;
  final double iconSize;
  final EdgeInsetsGeometry? padding;
  final String tooltipFavorite;
  final String tooltipUnfavorite;

  final Color? filledColor;
  final Color? outlineColor;

  @override
  Widget build(BuildContext context) {
    if (!ref.hasValidCoordinates) return const SizedBox.shrink();

    return BlocBuilder<FavoritePoiCubit, FavoritePoiState>(
      buildWhen: (prev, next) =>
          prev.poiScores != next.poiScores ||
          prev.affinityLoading != next.affinityLoading,
      builder: (context, state) {
        final filled = deriveMapPoiFavorited(state.poiScores, ref);
        final accent = filledColor ?? context.mapControlAccent;
        final cs = Theme.of(context).colorScheme;
        final line = outlineColor ?? cs.onSurfaceVariant;

        return IconButton(
          tooltip: filled ? tooltipUnfavorite : tooltipFavorite,
          padding: padding,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          visualDensity: VisualDensity.compact,
          onPressed: state.affinityLoading ? null : () => _onPressed(context, filled),
          icon: Icon(
            filled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: iconSize,
            color: filled ? accent : line,
          ),
        );
      },
    );
  }

  Future<void> _onPressed(BuildContext context, bool wasFavorite) async {
    final cubit = context.read<FavoritePoiCubit>();
    final outcome = await cubit.toggle(ref);
    if (!context.mounted) return;
    if (outcome == FavoriteToggleOutcome.failed && !wasFavorite) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Couldn't update favorites. Try again."),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
