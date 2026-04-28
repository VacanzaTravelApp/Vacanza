import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// ── Data model ─────────────────────────────────────────────────────────────

enum TopNotifType { checkin, badge }

class TopNotifData {
  final TopNotifType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> iconGradient;

  const TopNotifData({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconGradient,
  });
}

// ── Banner widget ───────────────────────────────────────────────────────────

/// A card that slides down from the top of the screen, lingers for
/// [displayDuration], then slides back up and calls [onDismissed].
///
/// Place it inside a [Stack] with a [Positioned] at the top.
class TopNotificationBanner extends StatefulWidget {
  const TopNotificationBanner({
    super.key,
    required this.data,
    required this.onDismissed,
    this.displayDuration = const Duration(milliseconds: 3500),
  });

  final TopNotifData data;
  final VoidCallback onDismissed;
  final Duration displayDuration;

  @override
  State<TopNotificationBanner> createState() => _TopNotificationBannerState();
}

class _TopNotificationBannerState extends State<TopNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  Timer? _autoTimer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 300),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -1.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6),
      reverseCurve: Curves.easeIn,
    );

    _ctrl.forward();
    _autoTimer = Timer(widget.displayDuration, _dismiss);
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_dismissing) return;
    _dismissing = true;
    _autoTimer?.cancel();
    _ctrl.reverse().whenComplete(() {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final padding = MediaQuery.of(context).padding;

    final accentColor = widget.data.iconGradient.first;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: GestureDetector(
          onVerticalDragUpdate: (d) {
            if (d.primaryDelta != null && d.primaryDelta! < -4) _dismiss();
          },
          onTap: _dismiss,
          child: Padding(
            padding: EdgeInsets.only(
              top: padding.top + 10,
              left: 14,
              right: 14,
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isLight
                      ? t.cardBg.withValues(alpha: 0.97)
                      : cs.surface.withValues(alpha: 0.96),
                  border: Border.all(
                    color: accentColor.withValues(alpha: isLight ? 0.22 : 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: isLight ? 0.12 : 0.18),
                      blurRadius: 24,
                      spreadRadius: 0,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isLight ? 0.08 : 0.38),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Accent left edge stripe
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 3.5,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: widget.data.iconGradient,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                        child: Row(
                          children: [
                            _IconCircle(
                              icon: widget.data.icon,
                              gradient: widget.data.iconGradient,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.data.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: t.textMain,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.data.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: t.textSub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: t.textSub.withValues(alpha: 0.55),
                            ),
                          ],
                        ),
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

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.icon, required this.gradient});

  final IconData icon;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.32),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 20, color: Colors.white),
    );
  }
}
