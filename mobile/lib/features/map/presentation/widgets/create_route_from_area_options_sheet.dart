import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/vacanza_gradient_button.dart';

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

Future<CreateRouteFromAreaOptions?> showCreateRouteFromAreaOptionsSheet(
  BuildContext context,
) {
  return showDialog<CreateRouteFromAreaOptions>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => const _CreateRouteFromAreaDialog(),
  );
}

const _kTravelStyles = <String, (String, IconData)>{
  'general': ('Balanced', Icons.tune_rounded),
  'history': ('Historical', Icons.account_balance_rounded),
  'food': ('Gourmet', Icons.local_dining_rounded),
  'nature': ('Outdoors', Icons.terrain_rounded),
};

class _CreateRouteFromAreaDialog extends StatefulWidget {
  const _CreateRouteFromAreaDialog();

  @override
  State<_CreateRouteFromAreaDialog> createState() =>
      _CreateRouteFromAreaState();
}

class _CreateRouteFromAreaState extends State<_CreateRouteFromAreaDialog> {
  static const int _minDays = 1;
  static const int _maxDays = 7;

  int _days = 3;
  String _travelStyle = 'general';
  bool _includeFavorites = true;

  void _submit() {
    Navigator.of(context).pop(
      CreateRouteFromAreaOptions(
        totalDays: _days,
        travelStyle: _travelStyle,
        includeFavorites: _includeFavorites,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.mapControlAccent;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final t = context.vacanzaTokens;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 360.0,
          maxHeight: MediaQuery.sizeOf(context).height * 0.80,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: isLight
                      ? context.lightGlassPanelColor.withValues(alpha: 0.97)
                      : t.glassBg,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: t.cardBorder.withValues(
                      alpha: isLight ? 0.35 : 0.45,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isLight ? 0.12 : 0.50,
                      ),
                      blurRadius: 48,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _GradientBar(accent: accent),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 14, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accent,
                                  accent.withValues(alpha: 0.65),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.28),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.route_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Plan a Route',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.6,
                                    color: t.textMain,
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  'AI-powered itinerary',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: t.textSub,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(999),
                            child: Ink(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isLight
                                    ? Colors.black.withValues(alpha: 0.06)
                                    : Colors.white.withValues(alpha: 0.08),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: t.textMain.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _DaySelector(
                              days: _days,
                              minDays: _minDays,
                              maxDays: _maxDays,
                              accent: accent,
                              isLight: isLight,
                              onChanged: (v) => setState(() => _days = v),
                            ),
                            const SizedBox(height: 20),
                            _SectionLabel(text: 'Travel Style'),
                            const SizedBox(height: 10),
                            _TravelStyleGrid(
                              value: _travelStyle,
                              accent: accent,
                              isLight: isLight,
                              onChanged: (v) =>
                                  setState(() => _travelStyle = v),
                            ),
                            const SizedBox(height: 20),
                            _FavoritesToggle(
                              value: _includeFavorites,
                              accent: accent,
                              isLight: isLight,
                              onChanged: (v) =>
                                  setState(() => _includeFavorites = v),
                            ),
                            const SizedBox(height: 22),
                            VacanzaGradientButton(
                              label: 'Create Route',
                              onPressed: _submit,
                              enabled: true,
                              minHeight: 52,
                              borderRadius: 16,
                            ),
                            CupertinoButton(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: t.textSub,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
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

// ── Gradient bar ───────────────────────────────────────────────────────────

class _GradientBar extends StatelessWidget {
  const _GradientBar({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.15),
            accent,
            accent.withValues(alpha: 0.15),
          ],
        ),
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: t.textSub.withValues(alpha: 0.70),
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Day selector ───────────────────────────────────────────────────────────

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.days,
    required this.minDays,
    required this.maxDays,
    required this.accent,
    required this.isLight,
    required this.onChanged,
  });

  final int days;
  final int minDays;
  final int maxDays;
  final Color accent;
  final bool isLight;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(text: 'Trip Duration'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: isLight
                ? Colors.black.withValues(alpha: 0.03)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: isLight
                  ? Colors.black.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _StepButton(
                    icon: CupertinoIcons.minus,
                    enabled: days > minDays,
                    accent: accent,
                    isLight: isLight,
                    onTap: days > minDays ? () => onChanged(days - 1) : null,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [accent, accent.withValues(alpha: 0.70)],
                          ).createShader(bounds),
                          child: Text(
                            '$days',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -2,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          days == 1 ? 'day' : 'days',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: t.textSub,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StepButton(
                    icon: CupertinoIcons.plus,
                    enabled: days < maxDays,
                    accent: accent,
                    isLight: isLight,
                    onTap: days < maxDays ? () => onChanged(days + 1) : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(maxDays, (i) {
                  final active = i < days;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: active ? 20 : 7,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: active
                          ? accent
                          : (isLight
                              ? Colors.black.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.14)),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.accent,
    required this.isLight,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final Color accent;
  final bool isLight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.38,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isLight ? Colors.white.withValues(alpha: 0.90) : null,
            border: isLight
                ? Border.all(color: Colors.black.withValues(alpha: 0.10))
                : null,
            gradient: isLight
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.90),
                      accent.withValues(alpha: 0.60),
                    ],
                  ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: isLight
                          ? Colors.black.withValues(alpha: 0.10)
                          : accent.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, size: 20, color: isLight ? accent : Colors.white),
        ),
      ),
    );
  }
}

// ── Travel style grid ──────────────────────────────────────────────────────

class _TravelStyleGrid extends StatelessWidget {
  const _TravelStyleGrid({
    required this.value,
    required this.accent,
    required this.isLight,
    required this.onChanged,
  });

  final String value;
  final Color accent;
  final bool isLight;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final entries = _kTravelStyles.entries.toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.6,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final key = entries[index].key;
        final (label, icon) = entries[index].value;
        final selected = value == key;

        return GestureDetector(
          onTap: () => onChanged(key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accent, accent.withValues(alpha: 0.70)],
                    )
                  : null,
              color: selected
                  ? null
                  : (isLight
                      ? Colors.black.withValues(alpha: 0.04)
                      : Colors.white.withValues(alpha: 0.06)),
              border: Border.all(
                color: selected
                    ? accent.withValues(alpha: 0.55)
                    : (isLight
                        ? Colors.black.withValues(alpha: 0.09)
                        : Colors.white.withValues(alpha: 0.11)),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: selected ? Colors.white : t.textSub),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : t.textMain,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Favorites toggle ───────────────────────────────────────────────────────

class _FavoritesToggle extends StatelessWidget {
  const _FavoritesToggle({
    required this.value,
    required this.accent,
    required this.isLight,
    required this.onChanged,
  });

  final bool value;
  final Color accent;
  final bool isLight;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isLight
            ? Colors.black.withValues(alpha: 0.03)
            : Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: isLight
              ? Colors.black.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x1FEF4444),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 14,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Include liked places',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: t.textMain,
                  ),
                ),
                Text(
                  'Liked POIs inside the area are offered to the AI',
                  style: TextStyle(fontSize: 11, color: t.textSub, height: 1.3),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: accent,
          ),
        ],
      ),
    );
  }
}
