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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 10, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: t.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: t.textSub,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, color: t.textSub),
          ),
        ],
      ),
    );
  }
}