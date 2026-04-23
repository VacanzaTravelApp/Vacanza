import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/theme_cubit.dart';

/// Profil → Görünüm: sistem / zamanlanmış gece / manuel.
Future<void> showAppearanceSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => const _AppearanceSettingsBody(),
  );
}

class _AppearanceSettingsBody extends StatelessWidget {
  const _AppearanceSettingsBody();

  static String _formatMinutes(int m) {
    final h = m ~/ 60;
    final min = m % 60;
    return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime(
    BuildContext context, {
    required bool isStart,
  }) async {
    final cubit = context.read<ThemeCubit>();
    final s = cubit.state;
    final minutes = isStart ? s.nightStartMinutes : s.nightEndMinutes;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked == null) return;
    final v = picked.hour * 60 + picked.minute;
    if (isStart) {
      await cubit.setNightWindow(
        nightStartMinutes: v,
        nightEndMinutes: s.nightEndMinutes,
      );
    } else {
      await cubit.setNightWindow(
        nightStartMinutes: s.nightStartMinutes,
        nightEndMinutes: v,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textSub = Theme.of(context).textTheme.bodySmall?.color;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: BlocBuilder<ThemeCubit, ThemeCubitState>(
          builder: (context, s) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scheduled mode uses your night hours (e.g. evening to morning). '
                  'The map sun/moon button switches to manual mode.',
                  style: TextStyle(fontSize: 13, color: textSub),
                ),
                const SizedBox(height: 16),
                RadioListTile<AppThemeStrategy>(
                  title: const Text('System default'),
                  subtitle: Text(
                    'Match device light/dark setting',
                    style: TextStyle(fontSize: 12, color: textSub),
                  ),
                  value: AppThemeStrategy.system,
                  groupValue: s.strategy,
                  onChanged: (v) {
                    if (v != null) context.read<ThemeCubit>().setStrategy(v);
                  },
                  activeColor: scheme.primary,
                ),
                RadioListTile<AppThemeStrategy>(
                  title: const Text('Scheduled'),
                  subtitle: Text(
                    'Night theme between ${_formatMinutes(s.nightStartMinutes)} '
                    'and ${_formatMinutes(s.nightEndMinutes)}',
                    style: TextStyle(fontSize: 12, color: textSub),
                  ),
                  value: AppThemeStrategy.scheduled,
                  groupValue: s.strategy,
                  onChanged: (v) {
                    if (v != null) context.read<ThemeCubit>().setStrategy(v);
                  },
                  activeColor: scheme.primary,
                ),
                if (s.strategy == AppThemeStrategy.scheduled) ...[
                  const SizedBox(height: 4),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.schedule, color: scheme.primary),
                    title: const Text('Night starts'),
                    trailing: Text(
                      _formatMinutes(s.nightStartMinutes),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () => _pickTime(context, isStart: true),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.wb_sunny_outlined, color: scheme.primary),
                    title: const Text('Night ends (day theme after)'),
                    trailing: Text(
                      _formatMinutes(s.nightEndMinutes),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () => _pickTime(context, isStart: false),
                  ),
                ],
                RadioListTile<AppThemeStrategy>(
                  title: const Text('Manual'),
                  subtitle: Text(
                    'Choose light or dark; map toggle updates this',
                    style: TextStyle(fontSize: 12, color: textSub),
                  ),
                  value: AppThemeStrategy.manual,
                  groupValue: s.strategy,
                  onChanged: (v) {
                    if (v != null) context.read<ThemeCubit>().setStrategy(v);
                  },
                  activeColor: scheme.primary,
                ),
                if (s.strategy == AppThemeStrategy.manual) ...[
                  const SizedBox(height: 4),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {s.manualMode},
                    onSelectionChanged: (set) {
                      final m = set.first;
                      context.read<ThemeCubit>().setManualMode(m);
                    },
                  ),
                ],
                const SizedBox(height: 12),
              ],
            );
          },
        ),
      ),
    );
  }
}
