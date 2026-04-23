import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/vacanza_gradient_button.dart';

/// Result for [ActiveRouteCubit.createFromPolygon]. Backend expects a single
/// `travelStyle` string; multiple chip selections are joined with ", ".
class CreateRouteFromAreaOptions {
  const CreateRouteFromAreaOptions({
    required this.totalDays,
    this.travelStyle,
    this.includeFavorites = true,
  });

  final int totalDays;
  final String? travelStyle;
  final bool includeFavorites;
}

/// Route params bottom sheet (web parity: Plan a Route modal).
Future<CreateRouteFromAreaOptions?> showCreateRouteFromAreaOptionsSheet(
  BuildContext context,
) {
  return showDialog<CreateRouteFromAreaOptions>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (_) => const _CreateRouteFromAreaDialog(),
  );
}

class _CreateRouteFromAreaDialog extends StatefulWidget {
  const _CreateRouteFromAreaDialog();

  @override
  State<_CreateRouteFromAreaDialog> createState() => _CreateRouteFromAreaState();
}

class _CreateRouteFromAreaState extends State<_CreateRouteFromAreaDialog> {
  static const int _minDays = 1;
  static const int _maxDays = 14;

  int _days = 3;
  String _travelStyle = 'general';
  bool _includeFavorites = true;

  static const _travelStyleOptions = <String, String>{
    'general': 'Balanced',
    'history': 'Historical',
    'food': 'Gourmet',
    'nature': 'Outdoors',
  };

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final accent = context.mapControlAccent;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final dialogMaxW = 380.0;
    final dialogMaxH = MediaQuery.sizeOf(context).height * 0.72;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogMaxW, maxHeight: dialogMaxH),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Material(
              color: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
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
                      color: Colors.black.withValues(alpha: isLight ? 0.18 : 0.55),
                      blurRadius: 32,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AccentHeaderBar(accent: accent),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 10, 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'Plan a Route',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.7,
                                color: t.textMain,
                                height: 1.12,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(999),
                            child: Ink(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isLight
                                        ? Colors.black.withValues(alpha: 0.06)
                                        : Colors.white.withValues(alpha: 0.08),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: t.textMain.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                      _FieldLabel(text: 'Trip Duration (Days)', color: t.textMain),
                      const SizedBox(height: 8),
                      _NumberFieldShell(
                        isLight: isLight,
                        child: Row(
                          children: [
                            _DayStepButton(
                              icon: CupertinoIcons.minus,
                              enabled: _days > _minDays,
                              accent: accent,
                              onTap:
                                  _days > _minDays
                                      ? () => setState(() => _days--)
                                      : null,
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  '$_days',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3,
                                    color: t.textMain,
                                  ),
                                ),
                              ),
                            ),
                            _DayStepButton(
                              icon: CupertinoIcons.plus,
                              enabled: _days < _maxDays,
                              accent: accent,
                              onTap:
                                  _days < _maxDays
                                      ? () => setState(() => _days++)
                                      : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _FieldLabel(text: 'Preferred Travel Style', color: t.textMain),
                      const SizedBox(height: 8),
                      _SelectFieldShell(
                        isLight: isLight,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _travelStyle,
                            isExpanded: true,
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: t.textSub,
                            ),
                            items:
                                _travelStyleOptions.entries.map((e) {
                                  return DropdownMenuItem<String>(
                                    value: e.key,
                                    child: Text(
                                      e.value,
                                      style: TextStyle(
                                        color: t.textMain,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _travelStyle = v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _FieldLabel(
                        text: 'Include my liked places',
                        color: t.textMain,
                        leading: Icon(
                          Icons.favorite_rounded,
                          size: 18,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ToggleFieldShell(
                        isLight: isLight,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Liked POIs inside the drawn area are offered to the AI.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.35,
                                  color: t.textSub,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Switch.adaptive(
                              value: _includeFavorites,
                              onChanged: (v) => setState(() => _includeFavorites = v),
                              activeTrackColor: accent,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      VacanzaGradientButton(
                        label: 'Done',
                        onPressed: () {
                          Navigator.of(context).pop(
                            CreateRouteFromAreaOptions(
                              totalDays: _days,
                              travelStyle: _travelStyle,
                              includeFavorites: _includeFavorites,
                            ),
                          );
                        },
                        enabled: true,
                        minHeight: 50,
                        borderRadius: 14,
                      ),
                      const SizedBox(height: 8),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: t.textSub,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
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
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text, required this.color, this.leading});

  final String text;
  final Color color;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

class _NumberFieldShell extends StatelessWidget {
  const _NumberFieldShell({required this.child, required this.isLight});

  final Widget child;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isLight ? Colors.black.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color:
              isLight
                  ? Colors.black.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: t.textMain),
        child: child,
      ),
    );
  }
}

class _SelectFieldShell extends StatelessWidget {
  const _SelectFieldShell({required this.child, required this.isLight});

  final Widget child;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isLight ? Colors.black.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color:
              isLight
                  ? Colors.black.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}

class _ToggleFieldShell extends StatelessWidget {
  const _ToggleFieldShell({required this.child, required this.isLight});

  final Widget child;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isLight ? Colors.black.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color:
              isLight
                  ? Colors.black.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: child,
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
    required this.accent,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    // Day mode: use a light button surface + orange icon (theme accent),
    // so the +/− stays visible even when accent is bright.
    final dayBg =
        enabled
            ? Colors.white.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.60);
    final dayBorder =
        enabled
            ? Colors.black.withValues(alpha: 0.10)
            : Colors.black.withValues(alpha: 0.06);

    // Night mode: keep gradient + white icon.
    final nightA =
        enabled ? accent.withValues(alpha: 0.95) : accent.withValues(alpha: 0.35);
    final nightB =
        enabled ? accent.withValues(alpha: 0.65) : accent.withValues(alpha: 0.30);

    final iconColor =
        isLight ? accent : Colors.white;

    return Opacity(
      opacity: enabled ? 1 : 0.62,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isLight ? dayBg : null,
            border:
                isLight ? Border.all(color: dayBorder) : null,
            gradient:
                isLight
                    ? null
                    : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [nightA, nightB],
                    ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isLight ? 0.14 : 0.42),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 22,
            color: iconColor.withValues(alpha: enabled ? 1 : 0.92),
          ),
        ),
      ),
    );
  }
}
