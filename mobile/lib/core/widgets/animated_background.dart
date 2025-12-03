import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = _controller.value;

        return Stack(
          children: [
            // Ana gradient (Figma)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.bgFrom,
                    AppColors.bgVia,
                    AppColors.bgTo,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // Üst sağ mavi glow
            _BlurCircle(
              color: AppColors.blobBlue,
              size: 260,
              blur: 120,
              alignment: Alignment(0.7, -0.8 + 0.04 * t),
              opacity: 0.15 + 0.05 * t,
            ),

            // Alt sol turkuaz glow
            _BlurCircle(
              color: AppColors.blobTeal,
              size: 230,
              blur: 100,
              alignment: Alignment(-0.8, 0.7 + 0.03 * t),
              opacity: 0.12,
            ),

            // Ortada hafif mavi glow
            _BlurCircle(
              color: AppColors.blobBlue,
              size: 200,
              blur: 100,
              alignment: Alignment(-0.1, 0.1 - 0.03 * t),
              opacity: 0.10,
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
