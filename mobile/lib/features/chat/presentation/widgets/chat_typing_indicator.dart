import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ChatTypingIndicator extends StatefulWidget {
  const ChatTypingIndicator({super.key});

  @override
  State<ChatTypingIndicator> createState() => _ChatTypingIndicatorState();
}

class _ChatTypingIndicatorState extends State<ChatTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bubbleRadius = BorderRadius.circular(18);

    final outlineGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        t.accentGradient[0].withValues(alpha: isLight ? 0.55 : 0.50),
        t.accentGradient[1].withValues(alpha: isLight ? 0.30 : 0.28),
        t.accentGradient[2].withValues(alpha: isLight ? 0.45 : 0.40),
      ],
    );

    final fill =
        isLight
            ? context.lightGlassBubbleFill
            : cs.surfaceContainerHighest.withValues(alpha: 0.40);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: bubbleRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLight ? 0.06 : 0.14),
                  blurRadius: isLight ? 14 : 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(1.2),
              decoration: BoxDecoration(
                borderRadius: bubbleRadius,
                gradient: outlineGradient,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: bubbleRadius,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isLight ? 0.35 : 0.10),
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final phase = (_controller.value + i * 0.2) % 1.0;
                        final offset =
                            (phase < 0.5
                                    ? Curves.easeOut.transform(phase * 2)
                                    : Curves.easeIn.transform(2 - phase * 2)) *
                                5;
                        return Padding(
                          padding: EdgeInsets.only(left: i > 0 ? 5 : 0),
                          child: Transform.translate(
                            offset: Offset(0, -offset),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: t.textSub.withValues(alpha: 0.75),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

