import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/load_status.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_section.dart';
import '../bloc/profile_state.dart';

class TravelStatisticsScreen extends StatelessWidget {
  const TravelStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left, size: 28),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          cs.surfaceContainerHighest.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Travel Statistics',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<ProfileBloc, ProfileState>(
                  buildWhen: (p, n) =>
                      p.statsStatus != n.statsStatus || p.stats != n.stats,
                  builder: (context, state) {
                    if (state.statsStatus == LoadStatus.loading &&
                        state.stats == null) {
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onSurfaceVariant,
                        ),
                      );
                    }
                    if (state.statsStatus == LoadStatus.failure) {
                      return Center(
                        child: Text(
                          state.errorFor(ProfileSection.stats) ?? 'Error',
                          style: TextStyle(color: cs.error),
                        ),
                      );
                    }
                    final stats = state.stats;
                    if (stats == null) {
                      return Center(
                        child: Text(
                          'No statistics available.',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      );
                    }
                    if (stats.visitedPoisCount == 0) {
                      return Center(
                        child: Text(
                          'No check-ins yet. Start exploring!',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      );
                    }

                    return GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      children: [
                        _StatTile(
                          label: 'Total places visited',
                          value: '${stats.visitedPoisCount}',
                        ),
                        _StatTile(
                          label: 'Last visit',
                          value: stats.lastVisitPoiName ?? '—',
                          subtitle: stats.lastVisitDate != null
                              ? '${stats.lastVisitDate!.year}-${stats.lastVisitDate!.month.toString().padLeft(2, '0')}-${stats.lastVisitDate!.day.toString().padLeft(2, '0')}'
                              : null,
                        ),
                        _StatTile(
                          label: 'Favorite category',
                          value: stats.favoriteCategory ?? '—',
                        ),
                        _StatTile(
                          label: 'Categories explored',
                          value: '${stats.distinctCategoriesCount}',
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  const _StatTile({required this.label, required this.value, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

