import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/widgets/vacanza_gradient_button.dart';

/// Shown when the map zoom is outside the valid draw range.
///
/// [tooHigh] = true  → user is too zoomed in  (area would be too small).
/// [tooHigh] = false → user is too zoomed out (neighbourhood-level required).
Future<void> showMapDrawAreaZoomHint(
  BuildContext context, {
  bool tooHigh = false,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.40),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return _ZoomHintDialog(tooHigh: tooHigh);
    },
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _ZoomHintDialog extends StatelessWidget {
  final bool tooHigh;
  const _ZoomHintDialog({required this.tooHigh});

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = context.mapControlAccent;

    final icon =
        tooHigh ? Icons.zoom_out_map_rounded : Icons.zoom_in_map_rounded;
    final title = tooHigh ? 'Zoom out to draw' : 'Zoom in to draw';
    final body = tooHigh
        ? "You're too zoomed in — the area would be too small to find interesting places. Zoom out a bit and try again."
        : 'This tool works at neighbourhood level. Pinch to zoom in — or move the map until you can see streets and blocks, then draw your area.';

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isLight ? context.lightGlassPanelColor : t.glassBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isLight
                            ? accent.withValues(alpha: 0.22)
                            : t.cardBorder,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isLight ? 0.10 : 0.38,
                          ),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                        if (!isLight)
                          BoxShadow(
                            color: accent.withValues(alpha: 0.10),
                            blurRadius: 28,
                          ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Gradient accent hairline
                        SizedBox(
                          height: 3,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: t.accentGradient),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(22),
                                topRight: Radius.circular(22),
                              ),
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Glowing icon badge
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(
                                        alpha: isLight ? 0.10 : 0.14,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: accent.withValues(
                                          alpha: isLight ? 0.22 : 0.32,
                                        ),
                                        width: 1,
                                      ),
                                      boxShadow: isLight
                                          ? null
                                          : [
                                              BoxShadow(
                                                color: accent.withValues(
                                                  alpha: 0.24,
                                                ),
                                                blurRadius: 14,
                                              ),
                                            ],
                                    ),
                                    child: Icon(icon, size: 24, color: accent),
                                  ),
                                  const SizedBox(width: 14),

                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                        color: t.textMain,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              Text(
                                body,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: t.textSub,
                                ),
                              ),

                              const SizedBox(height: 22),

                              VacanzaGradientButton(
                                label: 'Got it',
                                icon: Icons.check_rounded,
                                onPressed: () => Navigator.of(context).pop(),
                                enabled: true,
                                minHeight: 50,
                                borderRadius: 14,
                                textStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
