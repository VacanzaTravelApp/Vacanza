import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/vacanza_tokens.dart';

import 'package:mobile/features/profile/data/profile_preference_options.dart';

/// Result for [ActiveRouteCubit.createFromPolygon]. Backend expects a single
/// `travelStyle` string; multiple chip selections are joined with ", ".
class CreateRouteFromAreaOptions {
  const CreateRouteFromAreaOptions({
    required this.totalDays,
    this.travelStyle,
  });

  final int totalDays;
  final String? travelStyle;
}

/// Two-step bottom sheet: intro → trip length + multi-select travel styles.
Future<CreateRouteFromAreaOptions?> showCreateRouteFromAreaOptionsSheet(
  BuildContext context,
) {
  return showModalBottomSheet<CreateRouteFromAreaOptions>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.48),
    builder: (_) => const _CreateRouteFromAreaWizard(),
  );
}

class _CreateRouteFromAreaWizard extends StatefulWidget {
  const _CreateRouteFromAreaWizard();

  @override
  State<_CreateRouteFromAreaWizard> createState() =>
      _CreateRouteFromAreaWizardState();
}

class _CreateRouteFromAreaWizardState extends State<_CreateRouteFromAreaWizard> {
  static const int _minDays = 1;
  static const int _maxDays = 14;

  /// 0 = intro, 1 = details
  int _step = 0;

  int _days = 3;
  final LinkedHashSet<String> _travelStyles = LinkedHashSet<String>();

  String _travelStyleLabel(String key) {
    switch (key) {
      case 'RELAXATION':
        return 'Relaxation';
      case 'BACKPACKER':
        return 'Backpacker';
      default:
        return key[0] + key.substring(1).toLowerCase().replaceAll('_', ' ');
    }
  }

  String? _travelStyleForApi() {
    if (_travelStyles.isEmpty) return null;
    return _travelStyles.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final accent = context.mapControlAccent;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          constraints: BoxConstraints(
            maxHeight:
                _step == 0
                    ? MediaQuery.sizeOf(context).height * 0.50
                    : MediaQuery.sizeOf(context).height * 0.86,
          ),
          decoration: BoxDecoration(
            color:
                isLight
                    ? context.lightGlassPanelColor.withValues(alpha: 0.99)
                    : t.glassBg,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: t.cardBorder.withValues(alpha: isLight ? 0.45 : 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isLight ? 0.09 : 0.45),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AccentHeaderBar(accent: accent),
              Flexible(
                child:
                    _step == 0
                        ? _buildIntroScrollable(t, accent)
                        : _buildForm(t, accent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Scrollable so small sheet heights (e.g. shorter phones) never overflow.
  Widget _buildIntroScrollable(VacanzaTokens t, Color accent) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: accent, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            'AI route from your area',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.15,
              color: t.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll use the places inside your drawn region to build a day-by-day plan. '
            'This usually takes about 30–90 seconds.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.35,
              color: t.textSub,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.22)),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded, size: 19, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You\'ll choose trip length and optional travel vibes next.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: t.textMain,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CupertinoTheme(
            data: CupertinoThemeData(primaryColor: accent),
            child: CupertinoButton.filled(
              padding: const EdgeInsets.symmetric(vertical: 14),
              borderRadius: BorderRadius.circular(14),
              onPressed: () => setState(() => _step = 1),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 10),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: t.textSub,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(VacanzaTokens t, Color accent) {
    final scrollMaxH = (MediaQuery.sizeOf(context).height * 0.50).clamp(
      260.0,
      520.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
          child: Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                onPressed: () => setState(() => _step = 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.chevron_back, color: accent, size: 22),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  'Trip details',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: t.textMain,
                  ),
                ),
              ),
              const SizedBox(width: 72),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text(
            'How many days, and what kind of trip? Pick any travel styles that fit (optional).',
            style: TextStyle(fontSize: 14, height: 1.35, color: t.textSub),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text(
            'Trip length',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: t.textSub,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _DayStepButton(
              icon: CupertinoIcons.minus,
              enabled: _days > _minDays,
              onTap: _days > _minDays ? () => setState(() => _days--) : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                '$_days ${_days == 1 ? 'day' : 'days'}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: t.textMain,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            _DayStepButton(
              icon: CupertinoIcons.plus,
              enabled: _days < _maxDays,
              onTap: _days < _maxDays ? () => setState(() => _days++) : null,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
          child: Text(
            'Travel style (optional — multi-select)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: t.textSub,
            ),
          ),
        ),
        Expanded(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: scrollMaxH),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children:
                    optionTravelStyle.map((key) {
                      final sel = _travelStyles.contains(key);
                      return FilterChip(
                        label: Text(_travelStyleLabel(key)),
                        selected: sel,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _travelStyles.add(key);
                            } else {
                              _travelStyles.remove(key);
                            }
                          });
                        },
                        selectedColor: accent.withValues(alpha: 0.18),
                        checkmarkColor: accent,
                        labelStyle: TextStyle(
                          color: sel ? accent : t.textMain,
                          fontWeight:
                              sel ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
          child: Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: t.textSub,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: CupertinoTheme(
                  data: CupertinoThemeData(primaryColor: accent),
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    borderRadius: BorderRadius.circular(14),
                    onPressed: () {
                      Navigator.of(context).pop(
                        CreateRouteFromAreaOptions(
                          totalDays: _days,
                          travelStyle: _travelStyleForApi(),
                        ),
                      );
                    },
                    child: const Text(
                      'Create route',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccentHeaderBar extends StatelessWidget {
  const _AccentHeaderBar({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: 0.2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: 0.2),
                accent,
                accent.withValues(alpha: 0.2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DayStepButton extends StatelessWidget {
  const _DayStepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: t.pillSurface.withValues(alpha: enabled ? 0.95 : 0.4),
            border: Border.all(
              color: t.cardBorder.withValues(alpha: enabled ? 0.8 : 0.35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              size: 22,
              color: enabled ? t.textMain : t.textSub.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}
