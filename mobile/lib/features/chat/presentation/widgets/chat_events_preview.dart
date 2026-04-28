import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/event_mini_card.dart';
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
                  return EventMiniCard(
                    name: (e['name'] ?? 'Event').toString(),
                    thumbnail: pickEventThumbnail(e),
                    startLine: formatEventStartTime(e['startTime']?.toString()),
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

