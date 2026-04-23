import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../ai/data/api/ai_route_api_client.dart';

class ChatEventsPreview extends StatefulWidget {
  final String routeId;

  const ChatEventsPreview({super.key, required this.routeId});

  @override
  State<ChatEventsPreview> createState() => _ChatEventsPreviewState();
}

class _ChatEventsPreviewState extends State<ChatEventsPreview> {
  int _refresh = 0;
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AiRouteApiClient>().getEventRecommendations(
          widget.routeId,
        );
  }

  @override
  void didUpdateWidget(covariant ChatEventsPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeId != widget.routeId) {
      _future = context.read<AiRouteApiClient>().getEventRecommendations(
            widget.routeId,
          );
    }
  }

  String? _formatStart(String? startTime) {
    if (startTime == null || startTime.trim().isEmpty) return null;
    final d = DateTime.tryParse(startTime);
    if (d == null) return startTime;
    String two(int v) => v.toString().padLeft(2, '0');
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}, ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final accent = context.mapControlAccent;
    final _ = _refresh;

    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              ),
            ),
          );
        }

        final data = snap.data;
        final has = data?['hasRecommendations'] == true;
        final raw = data?['events'];
        final events = raw is List ? raw : const [];
        if (!has || events.isEmpty) {
          return Text(
            'No events found.',
            style: TextStyle(fontSize: 11.5, color: t.textSub),
          );
        }

        final window = data?['eventSearchWindow']?.toString();
        final isBroad = window == 'BROAD_30_DAYS';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBroad)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Showing about a month since no specific date was provided.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.25,
                    color: t.textSub,
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _refresh++;
                    _future = context
                        .read<AiRouteApiClient>()
                        .getEventRecommendations(widget.routeId);
                  });
                },
                child: Text(
                  'Refresh',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 142,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: events.length.clamp(0, 6),
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final e = events[i];
                  if (e is! Map) return const SizedBox.shrink();
                  String? thumb(dynamic raw) {
                    final s = raw?.toString().trim();
                    return (s == null || s.isEmpty) ? null : s;
                  }

                  String? pickThumb(Map e) {
                    return thumb(e['thumbnail']) ??
                        thumb(e['image']) ??
                        thumb(e['imageUrl']) ??
                        thumb(e['image_url']) ??
                        (() {
                          final imgs = e['images'];
                          if (imgs is List && imgs.isNotEmpty) {
                            final first = imgs.first;
                            if (first is Map) {
                              return thumb(first['url']) ?? thumb(first['secure_url']);
                            }
                            return thumb(first);
                          }
                          return null;
                        })();
                  }

                  return _EventMiniCard(
                    name: (e['name'] ?? 'Event').toString(),
                    thumbnail: pickThumb(e),
                    startLine: _formatStart(e['startTime']?.toString()),
                    venueName: e['venueName']?.toString(),
                    category: e['category']?.toString(),
                    matchedDay:
                        int.tryParse((e['matchedDay'] ?? '').toString()),
                    matchReason: e['matchReason']?.toString(),
                    ticketLink:
                        (e['ticketLink'] ?? e['ticket_link'])?.toString(),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EventMiniCard extends StatelessWidget {
  final String name;
  final String? thumbnail;
  final String? startLine;
  final String? venueName;
  final String? category;
  final int? matchedDay;
  final String? matchReason;
  final String? ticketLink;

  const _EventMiniCard({
    required this.name,
    required this.thumbnail,
    required this.startLine,
    required this.venueName,
    required this.category,
    required this.matchedDay,
    required this.matchReason,
    required this.ticketLink,
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

    return SizedBox(
      width: 168,
      child: Material(
        color: isLight ? context.lightGlassFieldFill : cs.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: hasTicket ? openTicket : null,
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
                                    colors: context.mapControlActiveGradientColors,
                                  ),
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
                          child: _Badge(
                            label: 'Day $matchedDay',
                            bg: Colors.black.withValues(alpha: 0.55),
                          ),
                        ),
                      if ((category ?? '').trim().isNotEmpty)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: _Badge(
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

class _Badge extends StatelessWidget {
  final String label;
  final Color bg;

  const _Badge({required this.label, required this.bg});

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

