import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import 'package:mobile/core/widgets/vacanza_gradient_button.dart';
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
  final bool isRouteEdit;

  const ChatRouteCard({
    super.key,
    required this.route,
    required this.summary,
    required this.routeId,
    required this.onShowOnMap,
    required this.onViewEvents,
    this.onDrawAreaOnMap,
    this.isRouteEdit = false,
  });

  @override
  State<ChatRouteCard> createState() => _ChatRouteCardState();
}

class _ChatRouteCardState extends State<ChatRouteCard> {
  bool _loadingPrices = false;
  String? _pricingError;
  List<WaypointPricingRow>? _pricingRows;
  bool _itineraryExpanded = false;
  bool _eventsExpanded = false;
  bool _pricesExpanded = false;

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

    bool looksNonEnglish(String text) {
      // Heuristic: Turkish characters often appear in backend summaries.
      // If present, prefer our English UI copy instead of showing mixed-language text.
      return RegExp(r'[ğĞıİşŞüÜçÇöÖ]').hasMatch(text);
    }

    final rawSummary = widget.summary?.trim();
    final shouldShowSummary =
        rawSummary != null &&
        rawSummary.isNotEmpty &&
        !looksNonEnglish(rawSummary);

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
            if (shouldShowSummary) ...[
              const SizedBox(height: 10),
              Text(
                rawSummary,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: t.textMain,
                ),
              ),
            ],
            // ── Day 1 preview (mirrors web) ──
            if (route.days.isNotEmpty) ...[
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final day1 = route.days.first;
                  final names = day1.waypoints
                      .map((w) => w.name)
                      .take(4)
                      .toList();
                  final more = (day1.waypoints.length - 4).clamp(0, 999);
                  if (names.isEmpty) return const SizedBox.shrink();
                  return Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Day 1: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: t.textSub,
                          ),
                        ),
                        TextSpan(
                          text: names.join(' · '),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: t.textSub,
                          ),
                        ),
                        if (more > 0)
                          TextSpan(
                            text: ' +$more',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ],
            // ── "Updated via chat" badge ──
            if (widget.isRouteEdit) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isLight ? 0.10 : 0.15),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, size: 13, color: accent),
                    const SizedBox(width: 5),
                    Text(
                      'Updated via chat',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            // ── Accordion: Itinerary ──
            _AccordionSection(
              title: 'Itinerary',
              subtitle: 'Stops${route.weatherForecast.isNotEmpty ? ' · Weather' : ''}',
              expanded: _itineraryExpanded,
              onToggle: () => setState(() => _itineraryExpanded = !_itineraryExpanded),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (route.weatherForecast.isNotEmpty) ...[
                    RouteWeatherStrip(route: route),
                    const SizedBox(height: 10),
                  ],
                  RouteDaysPreview(route: route),
                ],
              ),
            ),
            if (widget.routeId != null) ...[
              const SizedBox(height: 4),
              // ── Accordion: Event recommendations ──
              _AccordionSection(
                title: 'Event recommendations',
                subtitle: 'Ticketmaster — ranked by your preferences',
                expanded: _eventsExpanded,
                onToggle: () => setState(() => _eventsExpanded = !_eventsExpanded),
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
              // ── Accordion: Museum & tour prices ──
              _AccordionSection(
                title: 'Museum & tour prices',
                subtitle: 'Viator — products based on route stops',
                expanded: _pricesExpanded,
                onToggle: () => setState(() => _pricesExpanded = !_pricesExpanded),
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
              child: VacanzaGradientButton(
                label: 'Show on map',
                icon: Icons.map_rounded,
                onPressed: widget.onShowOnMap,
                enabled: true,
                minHeight: 46,
                borderRadius: 12,
                horizontalPadding: 18,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
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

class _AccordionSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool expanded;
  final VoidCallback onToggle;

  const _AccordionSection({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: t.cardBorder.withValues(alpha: 0.40)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tap header ──
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
              child: Row(
                children: [
                  Expanded(
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
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: t.textSub.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: t.textSub.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Collapsible content ──
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: child,
            ),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOut,
          ),
        ],
      ),
    );
  }
}

