import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class AuthCardContainer extends StatelessWidget {
  final Widget child;

  const AuthCardContainer({super.key, required this.child});
//sersss
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.vacanzaTokens;
    final isLight = theme.brightness == Brightness.light;
    final accent = context.authAccent;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: isLight
            ? Color.alphaBlend(
                Colors.white.withValues(alpha: 0.62),
                theme.colorScheme.surface.withValues(alpha: 0.92),
              )
            : tokens.glassBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: tokens.cardBorder),
        boxShadow: [
          BoxShadow(
            color: (isLight ? accent : tokens.pillShadowAccent)
                .withValues(alpha: isLight ? 0.10 : 0.18),
            blurRadius: isLight ? 18 : 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}