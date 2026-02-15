import 'package:flutter/material.dart';

/// Placeholder section for live challenges (future feature).
class ChallengesPlaceholder extends StatelessWidget {
  const ChallengesPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.track_changes, size: 20, color: Color(0xFF0096FF)),
            SizedBox(width: 8),
            Text(
              'Live Challenges',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          ),
          child: Text(
            'Coming soon — complete check-ins to unlock challenges!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ),
      ],
    );
  }
}
