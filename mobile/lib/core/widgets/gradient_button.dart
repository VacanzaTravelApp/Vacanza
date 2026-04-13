import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  /// true ise gradient görünüm, false ise disabled gri görünüm
  final bool active;

  /// true ise tıklanabilir (onTap çalışır)
  final bool enabled;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
    this.active = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tokens = context.vacanzaTokens;
    final isLight = theme.brightness == Brightness.light;

    final bool canTap = enabled && !loading && onPressed != null;
    final BorderRadius radius = BorderRadius.circular(26);

    final colors = context.authAccentGradientColors;
    final Color a = colors[0];
    final Color b = colors[1];

    final Decoration decoration = active
        ? BoxDecoration(
      borderRadius: radius,
      gradient: LinearGradient(
        colors: [a, b],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      boxShadow: [
        BoxShadow(
          color: (isLight ? a : tokens.pillShadowAccent)
              .withValues(alpha: isLight ? 0.22 : 0.30),
          blurRadius: isLight ? 14 : 20,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
      ],
    )
        : BoxDecoration(
      borderRadius: radius,
      color: theme.brightness == Brightness.light
          ? cs.surfaceContainerHighest.withValues(alpha: 0.55)
          : cs.surfaceContainerHighest.withValues(alpha: 0.35),
    );

    return ClipRRect(
      borderRadius: radius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: decoration,
        height: 52,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: canTap ? onPressed : null,
            child: Center(
              child: loading
                  ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
