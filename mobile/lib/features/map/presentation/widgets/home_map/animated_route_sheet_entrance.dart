import 'package:flutter/material.dart';

/// Soft entrance when the route sheet appears (no slide, so draggable hit targets stay reliable).
class AnimatedRouteSheetEntrance extends StatefulWidget {
  final Widget child;

  const AnimatedRouteSheetEntrance({super.key, required this.child});

  @override
  State<AnimatedRouteSheetEntrance> createState() =>
      _AnimatedRouteSheetEntranceState();
}

class _AnimatedRouteSheetEntranceState extends State<AnimatedRouteSheetEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  static const Duration _duration = Duration(milliseconds: 480);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _fade, child: widget.child);
  }
}
