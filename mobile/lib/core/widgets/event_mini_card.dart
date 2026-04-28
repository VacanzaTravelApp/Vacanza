import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

// ── Helpers ─────────────────────────────────────────────────────────────────

String? pickEventThumbnail(Map<dynamic, dynamic> e) {
  String? s(dynamic raw) {
    final v = raw?.toString().trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  return s(e['thumbnail']) ??
      s(e['image']) ??
      s(e['imageUrl']) ??
      s(e['image_url']) ??
      () {
        final imgs = e['images'];
        if (imgs is List && imgs.isNotEmpty) {
          final first = imgs.first;
          if (first is Map) return s(first['url']) ?? s(first['secure_url']);
          return s(first);
        }
        return null;
      }();
}

String? formatEventStartTime(String? startTime) {
  if (startTime == null || startTime.trim().isEmpty) return null;
  final d = DateTime.tryParse(startTime);
  if (d == null) return startTime;
  String two(int v) => v.toString().padLeft(2, '0');
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]}, ${two(d.hour)}:${two(d.minute)}';
}

// ── Card ─────────────────────────────────────────────────────────────────────

class EventMiniCard extends StatelessWidget {
  final String name;
  final String? thumbnail;
  final String? startLine;
  final String? venueName;
  final String? category;
  final int? matchedDay;
  final String? matchReason;
  final String? ticketLink;
  /// Called on tap when no [ticketLink] is available.
  final VoidCallback? onTapFallback;

  const EventMiniCard({
    super.key,
    required this.name,
    required this.thumbnail,
    required this.startLine,
    required this.venueName,
    required this.category,
    required this.matchedDay,
    required this.matchReason,
    required this.ticketLink,
    this.onTapFallback,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = context.mapControlAccent;
    final hasTicket = (ticketLink ?? '').trim().isNotEmpty;

    Future<void> openTicket() async {
      final href = ticketLink?.trim();
      if (href == null || href.isEmpty) return;
      final u = Uri.tryParse(href);
      if (u == null) return;
      if (await canLaunchUrl(u)) {
        await launchUrl(u, mode: LaunchMode.externalApplication);
      }
    }

    VoidCallback? tapHandler;
    if (hasTicket) {
      tapHandler = openTicket;
    } else if (onTapFallback != null) {
      tapHandler = onTapFallback;
    }

    return SizedBox(
      width: 168,
      child: Material(
        color: isLight ? context.lightGlassFieldFill : cs.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: tapHandler,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: t.cardBorder.withValues(alpha: isLight ? 0.40 : 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      if ((thumbnail ?? '').trim().isNotEmpty)
                        Positioned.fill(
                          child: Image.network(
                            thumbnail!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors:
                                        context.mapControlActiveGradientColors,
                                  ),
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        )
                      else
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: context.mapControlActiveGradientColors,
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.00),
                                Colors.black.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (matchedDay != null)
                        Positioned(
                          left: 8,
                          top: 8,
                          child: EventMiniCardBadge(
                            label: 'Day $matchedDay',
                            bg: Colors.black.withValues(alpha: 0.55),
                          ),
                        ),
                      if ((category ?? '').trim().isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: EventMiniCardBadge(
                            label: category!,
                            bg: accent.withValues(alpha: 0.75),
                          ),
                        ),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 8,
                        child: Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((startLine ?? '').trim().isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: t.textSub.withValues(alpha: 0.85),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                startLine!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: t.textMain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if ((venueName ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          venueName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: t.textSub,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if ((matchReason ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          matchReason!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.2,
                            color: t.textSub.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pill badge ────────────────────────────────────────────────────────────────

class EventMiniCardBadge extends StatelessWidget {
  final String label;
  final Color bg;

  const EventMiniCardBadge({super.key, required this.label, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}
