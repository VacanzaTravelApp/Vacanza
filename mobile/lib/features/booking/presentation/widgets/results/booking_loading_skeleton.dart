import 'package:flutter/material.dart';

import '../search/booking_search_field_styles.dart';

/// Animated shimmer-like loading skeleton for result cards.
class BookingLoadingSkeleton extends StatefulWidget {
  const BookingLoadingSkeleton({super.key});

  @override
  State<BookingLoadingSkeleton> createState() => _BookingLoadingSkeletonState();
}

class _BookingLoadingSkeletonState extends State<BookingLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity =
            0.3 + 0.4 * (0.5 + 0.5 * (_controller.value * 2 - 1).abs());
        return Column(
          children: List.generate(3, (i) => _skeletonCard(context, opacity)),
        );
      },
    );
  }

  Widget _skeletonCard(BuildContext context, double opacity) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border.all(
            color: BookingSearchFieldStyles.fieldBorderInactive(context),
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bar(cs, opacity, width: double.infinity, height: 14),
            const SizedBox(height: 8),
            _bar(cs, opacity, width: 160, height: 10),
            const SizedBox(height: 8),
            _bar(cs, opacity, width: 80, height: 10),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _bar(cs, opacity, width: 60, height: 16),
                _bar(cs, opacity, width: 90, height: 28),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(
    ColorScheme cs,
    double pulseOpacity, {
    required double width,
    required double height,
  }) {
    final a = (0.25 + 0.35 * pulseOpacity).clamp(0.0, 1.0);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cs.outline.withValues(alpha: a),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
