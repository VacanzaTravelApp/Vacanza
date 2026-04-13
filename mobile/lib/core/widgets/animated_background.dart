import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.vacanzaTokens;
    final isLight = theme.brightness == Brightness.light;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = _controller.value;

        final bgA = tokens.bgMain;
        final bgB = isLight
            ? Color.alphaBlend(
                Colors.white.withValues(alpha: 0.55),
                tokens.glassBg,
              )
            : Color.alphaBlend(
                tokens.vividSubtleBg.withValues(alpha: 0.22),
                tokens.bgMain,
              );
        final bgC = isLight
            ? Color.alphaBlend(
                Colors.white.withValues(alpha: 0.65),
                tokens.bgMain,
              )
            : Color.alphaBlend(
                tokens.vividSubtleBg.withValues(alpha: 0.12),
                tokens.bgMain,
              );

        return Stack(
          children: [
            // Theme-aware gradient base (day/night)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [bgA, bgB, bgC],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // Top-right glow
            _BlurCircle(
              color: isLight ? tokens.vividCoral : tokens.vividBlue,
              size: isLight ? 260 : 240,
              blur: isLight ? 120 : 140,
              alignment: Alignment(0.7, -0.8 + 0.04 * t),
              opacity: (isLight ? 0.14 : 0.10) + (isLight ? 0.05 : 0.03) * t,
            ),

            // Bottom-left glow
            _BlurCircle(
              color: tokens.vividCoral,
              size: isLight ? 230 : 220,
              blur: isLight ? 100 : 140,
              alignment: Alignment(-0.8, 0.7 + 0.03 * t),
              opacity: isLight ? 0.10 : 0.07,
            ),

            // Mid glow
            _BlurCircle(
              color: tokens.vividAmber,
              size: isLight ? 200 : 190,
              blur: isLight ? 100 : 150,
              alignment: Alignment(-0.1, 0.1 - 0.03 * t),
              opacity: isLight ? 0.06 : 0.04,
            ),

            // (İstersek dotted orbitleri sonra ekleriz)

            widget.child,
          ],
        );
      },
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final Color color;
  final double size;
  final double blur;
  final Alignment alignment;
  final double opacity;

  const _BlurCircle({
    required this.color,
    required this.size,
    required this.blur,
    required this.alignment,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}
