import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/loading_tips.dart';

/// Typing indicator bubble with optional travel-tip card (mirrors web).
///
/// When [currentTip] is provided the bubble expands to show the tip below
/// the bouncing dots — exactly like the web's `chat-typing-bubble` with
/// `.chat-tip-card`.
class ChatTypingIndicator extends StatefulWidget {
  /// Currently displayed travel tip. Rotated by the parent every ~9 s.
  final TravelTip? currentTip;

  /// Called when the user taps "next tip →".
  final VoidCallback? onNextTip;

  const ChatTypingIndicator({super.key, this.currentTip, this.onNextTip});

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
    final accent = context.mapControlAccent;
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
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: DecoratedBox(
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
              child: ClipRRect(
                borderRadius: bubbleRadius,
                child: Container(
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: bubbleRadius,
                    border: Border.all(
                      color:
                          Colors.white.withValues(alpha: isLight ? 0.35 : 0.10),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // ── Bouncing dots + "Thinking…" ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(3, (i) {
                                  final phase =
                                      (_controller.value + i * 0.2) % 1.0;
                                  final offset =
                                      (phase < 0.5
                                              ? Curves.easeOut
                                                  .transform(phase * 2)
                                              : Curves.easeIn
                                                  .transform(2 - phase * 2)) *
                                      5;
                                  return Padding(
                                    padding:
                                        EdgeInsets.only(left: i > 0 ? 5 : 0),
                                    child: Transform.translate(
                                      offset: Offset(0, -offset),
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: t.textSub.withValues(
                                            alpha: 0.75,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Thinking…',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: t.textSub,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Travel Tip Card ──
                      if (widget.currentTip != null)
                        _TipCard(
                          tip: widget.currentTip!,
                          onNextTip: widget.onNextTip,
                          accent: accent,
                        ),
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

/// Tip card rendered below the dots — matches web `.chat-tip-card`.
class _TipCard extends StatelessWidget {
  final TravelTip tip;
  final VoidCallback? onNextTip;
  final Color accent;

  const _TipCard({
    required this.tip,
    required this.onNextTip,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-0.04, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(tip.tip),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: accent, width: 3),
          ),
          color: accent.withValues(alpha: isLight ? 0.08 : 0.12),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TRAVEL TIP',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: accent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tip.tip,
              style: TextStyle(
                fontSize: 13,
                height: 1.55,
                color: t.textMain,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (tip.city != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isLight ? 0.15 : 0.20),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tip.city!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: t.textSub,
                      ),
                    ),
                  ),
                const Spacer(),
                if (onNextTip != null)
                  GestureDetector(
                    onTap: onNextTip,
                    child: Text(
                      'next tip →',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
