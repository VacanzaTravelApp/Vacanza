import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../ai/data/api/ai_route_api_client.dart';
import '../../data/models/chat_models.dart';
import 'chat_events_preview.dart';
import 'route_weather_strip.dart';

class ChatRouteCard extends StatefulWidget {
  final ChatRouteData route;
  final String? summary;
  final String? routeId;
  final VoidCallback onShowOnMap;
  final VoidCallback onViewEvents;
  final VoidCallback? onDrawAreaOnMap;

  const ChatRouteCard({
    super.key,
    required this.route,
    required this.summary,
    required this.routeId,
    required this.onShowOnMap,
    required this.onViewEvents,
    this.onDrawAreaOnMap,
  });

  @override
  State<ChatRouteCard> createState() => _ChatRouteCardState();
}

class _ChatRouteCardState extends State<ChatRouteCard> {
  bool _loadingPrices = false;
  String? _pricingError;
  List<WaypointPricingRow>? _pricingRows;
  bool _expanded = false;

  Future<void> _loadPrices() async {
    final id = widget.routeId;
    if (id == null) return;
    setState(() {
      _loadingPrices = true;
      _pricingError = null;
    });
    try {
      final rows = await context.read<AiRouteApiClient>().getRoutePricing(id);
      if (!mounted) return;
      setState(() {
        _loadingPrices = false;
        _pricingRows = rows;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingPrices = false;
        _pricingError = 'Could not load prices.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final route = widget.route;
    final days = route.totalDays > 0 ? route.totalDays : route.days.length;
    final stops = route.days.fold<int>(0, (acc, d) => acc + d.waypoints.length);

    final outlineGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        t.accentGradient[0].withValues(alpha: isLight ? 0.55 : 0.50),
        t.accentGradient[1].withValues(alpha: isLight ? 0.30 : 0.28),
        t.accentGradient[2].withValues(alpha: isLight ? 0.45 : 0.40),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isLight ? 0.06 : 0.14),
                  blurRadius: isLight ? 16 : 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(1.2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: outlineGradient,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isLight ? context.lightGlassPanelColor : cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: isLight ? 0.30 : 0.10,
                      ),
                    ),
                  ),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: t.accentGradient),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.onDrawAreaOnMap != null) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                            decoration: BoxDecoration(
                              color:
                                  isLight
                                      ? context.lightGlassFieldFill
                                      : cs.surfaceContainerHighest.withValues(
                                        alpha: 0.20,
                                      ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: t.cardBorder.withValues(
                                  alpha: isLight ? 0.35 : 0.30,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Redraw',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.7,
                                          color: t.textMain.withValues(
                                            alpha: 0.92,
                                          ),
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: widget.onDrawAreaOnMap,
                                      icon: Icon(
                                        Icons.draw_rounded,
                                        size: 18,
                                        color: accent,
                                      ),
                                      label: Text(
                                        'Draw on map',
                                        style: TextStyle(
                                          color: accent,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Draw an area on the map and select the day to reschedule that day.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    height: 1.25,
                                    color: t.textSub.withValues(alpha: 0.95),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Text(
              route.title?.trim().isNotEmpty == true ? route.title! : 'AI Route',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: t.textMain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${route.destination ?? 'Destination'} • $days day${days == 1 ? '' : 's'} • $stops stop${stops == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 12.5,
                color: t.textSub,
              ),
            ),
            if (route.tripStartDate != null &&
                route.tripStartDate!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Trip starts: ${route.tripStartDate}',
                style: TextStyle(
                  fontSize: 11.5,
                  color: t.textSub,
                ),
              ),
            ],
            if (widget.summary != null && widget.summary!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                widget.summary!,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: t.textMain,
                ),
              ),
            ],
            const SizedBox(height: 10),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _expanded ? 'Hide details' : 'Show details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: t.textSub,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              if (route.weatherForecast.isNotEmpty) ...[
                const SizedBox(height: 6),
                RouteWeatherStrip(route: route),
              ],
              const SizedBox(height: 10),
              RouteDaysPreview(route: route),
            ],
            if (widget.routeId != null) ...[
              const SizedBox(height: 12),
              _RouteSubsection(
                title: 'Event recommendations',
                subtitle: 'Ticketmaster — ranked by your preferences',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ChatEventsPreview(routeId: widget.routeId!),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: widget.onViewEvents,
                        icon: Icon(Icons.event_rounded, size: 18, color: accent),
                        label: Text(
                          'View all events',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (widget.routeId != null) ...[
              const SizedBox(height: 4),
              _RouteSubsection(
                title: 'Museum & tour prices',
                subtitle: 'Viator — products based on route stops',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _loadingPrices ? null : _loadPrices,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: accent.withValues(alpha: 0.85)),
                          foregroundColor: accent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _loadingPrices
                                ? SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: accent,
                                  ),
                                )
                                : const Text('Show prices'),
                      ),
                    ),
                    if (_pricingError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _pricingError!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    if (_pricingRows != null && _pricingRows!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ..._pricingRows!.take(4).map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                r.found && r.minPriceUsd != null
                                    ? '${r.waypointName}: from \$${r.minPriceUsd!.toStringAsFixed(0)} ${r.currency}'
                                    : '${r.waypointName}: ${r.message ?? '—'}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  height: 1.25,
                                  color: t.textMain,
                                ),
                              ),
                            ),
                          ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: widget.onShowOnMap,
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('Show on map'),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
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

class RouteDaysPreview extends StatelessWidget {
  final ChatRouteData route;

  const RouteDaysPreview({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    final days = route.days;
    if (days.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final d in days.take(4))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: t.vividSubtleBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: t.cardBorder.withValues(alpha: 0.8)),
                  ),
                  child: Text(
                    'Day ${d.day}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: t.textMain,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    d.waypoints.map((w) => w.name).take(6).join(', '),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.28,
                      color: t.textSub,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RouteSubsection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _RouteSubsection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: t.cardBorder.withValues(alpha: 0.40)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: t.textMain.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: t.textSub.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

