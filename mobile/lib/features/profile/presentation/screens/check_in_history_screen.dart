import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/load_status.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_section.dart';
import '../bloc/profile_state.dart';

class CheckInHistoryScreen extends StatelessWidget {
  const CheckInHistoryScreen({super.key});

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
                    'Check-in History',
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
                      p.checkInsStatus != n.checkInsStatus ||
                      p.checkIns != n.checkIns,
                  builder: (context, state) {
                    if (state.checkInsStatus == LoadStatus.loading &&
                        state.checkIns.isEmpty) {
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onSurfaceVariant,
                        ),
                      );
                    }
                    if (state.checkInsStatus == LoadStatus.failure) {
                      return Center(
                        child: Text(
                          state.errorFor(ProfileSection.checkIns) ?? 'Error',
                          style: TextStyle(color: cs.error),
                        ),
                      );
                    }
                    if (state.checkIns.isEmpty) {
                      return Center(
                        child: Text(
                          'No check-ins yet.',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: state.checkIns.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: cs.outline.withValues(alpha: 0.2),
                      ),
                      itemBuilder: (context, i) {
                        final c = state.checkIns[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.place_outlined,
                            color: cs.onSurfaceVariant,
                          ),
                          title: Text(
                            c.poiName,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            '${c.category} • ${c.checkedInAt.year}-${c.checkedInAt.month.toString().padLeft(2, '0')}-${c.checkedInAt.day.toString().padLeft(2, '0')}',
                            style: TextStyle(color: cs.onSurfaceVariant),
                          ),
                        );
                      },
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

