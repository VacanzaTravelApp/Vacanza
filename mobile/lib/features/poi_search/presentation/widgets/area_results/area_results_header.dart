import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class AreaResultsHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  const AreaResultsHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final accent = context.mapControlAccent;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon badge
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isLight ? 0.10 : 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: accent.withValues(alpha: isLight ? 0.20 : 0.28),
                width: 1,
              ),
              boxShadow: isLight
                  ? null
                  : [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.18),
                        blurRadius: 8,
                      ),
                    ],
            ),
            child: Icon(
              Icons.explore_rounded,
              size: 17,
              color: accent,
            ),
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: t.textMain,
                  ),
                ),
                const SizedBox(height: 3),
                // Count pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isLight ? 0.08 : 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: accent.withValues(alpha: isLight ? 0.15 : 0.22),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Close button
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onClose,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: t.textSub.withValues(alpha: 0.70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
