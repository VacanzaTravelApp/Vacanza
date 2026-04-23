import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ChatErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onDismiss;

  const ChatErrorBanner({super.key, required this.error, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.withValues(alpha: 0.85),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: TextStyle(fontSize: 13, color: t.textMain),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onDismiss,
            color: t.textSub,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

