import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class VacanzaGradientButton extends StatelessWidget {
  const VacanzaGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.enabled = true,
    this.loading = false,
    this.minHeight = 52,
    this.borderRadius = 20,
    this.horizontalPadding = 22,
    this.textStyle,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool loading;

  final double minHeight;
  final double borderRadius;
  final double horizontalPadding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final radius = BorderRadius.circular(borderRadius);
    final gradientColors = context.mapControlActiveGradientColors;
    final accent = context.mapControlAccent;

    final canTap = enabled && !loading && onPressed != null;

    final decoration =
        canTap
            ? BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: isLight ? 0.28 : 0.30),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLight ? 0.12 : 0.35),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            )
            : BoxDecoration(
              borderRadius: radius,
              color: cs.surfaceContainerHighest.withValues(
                alpha: isLight ? 0.70 : 0.45,
              ),
              border: Border.all(
                color: cs.outline.withValues(alpha: isLight ? 0.18 : 0.32),
              ),
            );

    final fg = canTap ? Colors.white : cs.onSurfaceVariant;
    final labelStyle =
        textStyle ??
        TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
          color: fg.withValues(alpha: canTap ? 0.98 : 0.92),
        );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      opacity: enabled ? 1 : 0.72,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: canTap ? onPressed : null,
          borderRadius: radius,
          splashColor: Colors.white.withValues(alpha: 0.14),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          child: Ink(
            decoration: decoration,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Center(
                  child:
                      loading
                          ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (icon != null) ...[
                                Icon(icon, size: 20, color: fg),
                                const SizedBox(width: 10),
                              ],
                              Text(label, style: labelStyle),
                            ],
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

