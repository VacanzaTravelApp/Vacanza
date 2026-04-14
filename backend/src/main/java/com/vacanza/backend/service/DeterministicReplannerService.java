package com.vacanza.backend.service;

import com.vacanza.backend.dto.adjustment.AdjustmentResult;
import com.vacanza.backend.dto.internal.PoiResult;
import com.vacanza.backend.entity.enums.AdjustmentSeverity;
import com.vacanza.backend.integration.MapboxPoiSearchClient;
import com.vacanza.backend.integration.ai.AiChatDto;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Tags;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;

/**
 * Replans an itinerary <em>without</em> an LLM call, keeping total latency well under
 * the 10-second SLA.
 *
 * <p>Strategy per affected waypoint:
 * <ol>
 *   <li>Mark the waypoint {@code unavailable = true}.</li>
 *   <li>If severity is {@code LOW}: stop here — waypoint stays visible but flagged.</li>
 *   <li>Otherwise: search Mapbox for a same-category replacement within ~1 km of the
 *       original coordinates.</li>
 *   <li>If a replacement is found: substitute the waypoint in-place (name, coords, category).
 *       Action = {@code REPLACED}.</li>
 *   <li>If no replacement found: remove the waypoint and renumber {@code order} fields.
 *       Action = {@code REMOVED}.</li>
 * </ol>
 *
 * <p>After all substitutions the day's timeline is re-enriched by
 * {@link RouteTimelineService} (arrival/departure times, walking durations).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DeterministicReplannerService {

    /** ~1 km in degrees at mid-latitudes. */
    private static final double REPLACEMENT_RADIUS_DEG = 0.01;

    /** Mapbox category search timeout (well under the 10-second SLA). */
    private static final Duration MAPBOX_TIMEOUT = Duration.ofSeconds(5);

    private final MapboxPoiSearchClient mapboxClient;
    private final RouteTimelineService timelineService;
    private final ObjectProvider<MeterRegistry> meterRegistry;

    /**
     * Applies deterministic adjustment to {@code routeData} for the named POI.
     *
     * @param routeData        mutable copy of the current route — modified in place
     * @param affectedPoiName  name of the unavailable POI (case-insensitive substring match)
     * @param affectedDay      if non-null, only the given day (1-based) is searched
     * @param severity         drives how aggressively we act
     * @return list of action summaries for the response body
     */
    public List<AdjustmentResult.WaypointActionSummary> replan(
            AiChatDto.RouteData routeData,
            String affectedPoiName,
            Integer affectedDay,
            AdjustmentSeverity severity,
            Set<String> historicallyExcluded) {

        List<AdjustmentResult.WaypointActionSummary> actions = new ArrayList<>();

        for (AiChatDto.DayPlan day : routeData.getDays()) {
            if (affectedDay != null && day.getDay() != affectedDay) continue;
            if (day.getWaypoints() == null) continue;

            List<AiChatDto.RouteWaypoint> toRemove = new ArrayList<>();

            for (AiChatDto.RouteWaypoint wp : day.getWaypoints()) {
                if (!nameMatches(wp.getName(), affectedPoiName)) continue;

                wp.setUnavailable(true);
                log.info("[ADAPTIVE] Day {} — '{}' marked unavailable (severity={})",
                        day.getDay(), wp.getName(), severity);

                if (severity == AdjustmentSeverity.LOW) {
                    actions.add(summaryOf(wp.getName(), day.getDay(), "MARKED_UNAVAILABLE", null));
                    recordMetric("marked_unavailable");
                    continue;
                }

                Optional<PoiResult> replacement = findReplacement(wp, historicallyExcluded);

                if (replacement.isPresent()) {
                    PoiResult r = replacement.get();
                    String originalName = wp.getName();
                    applyReplacement(wp, r);
                    log.info("[ADAPTIVE] Day {} — '{}' replaced with '{}' ({},{})",
                            day.getDay(), originalName, r.getName(), r.getLat(), r.getLon());
                    actions.add(summaryOf(originalName, day.getDay(), "REPLACED", r.getName()));
                    recordMetric("replaced");
                } else {
                    log.info("[ADAPTIVE] Day {} — '{}' removed (no replacement found)",
                            day.getDay(), wp.getName());
                    actions.add(summaryOf(wp.getName(), day.getDay(), "REMOVED", null));
                    toRemove.add(wp);
                    recordMetric("removed");
                }
            }

            // Remove waypoints with no replacement and renumber
            if (!toRemove.isEmpty()) {
                day.getWaypoints().removeAll(toRemove);
                renumberOrders(day.getWaypoints());
            }
        }

        // Re-compute arrival / departure times for any changed days
        timelineService.enrichTimeline(routeData);

        return actions;
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    private boolean nameMatches(String waypointName, String targetName) {
        if (waypointName == null || targetName == null) return false;
        return waypointName.toLowerCase(Locale.ROOT)
                .contains(targetName.toLowerCase(Locale.ROOT));
    }

    private Optional<PoiResult> findReplacement(AiChatDto.RouteWaypoint wp, Set<String> historicallyExcluded) {
        if (wp.getLatitude() == null || wp.getLongitude() == null) return Optional.empty();

        double lat = wp.getLatitude();
        double lon = wp.getLongitude();
        double r   = REPLACEMENT_RADIUS_DEG;

        String category = wp.getCategory() != null ? wp.getCategory() : "tourist_attraction";

        try {
            List<PoiResult> candidates = mapboxClient
                    .searchByCategory(category, lon - r, lat - r, lon + r, lat + r)
                    .block(MAPBOX_TIMEOUT);

            if (candidates == null || candidates.isEmpty()) return Optional.empty();

            // Exclude: (1) the unavailable POI itself, (2) any POI rejected in prior adjustments
            return candidates.stream()
                    .filter(c -> !nameMatches(c.getName(), wp.getName()))
                    .filter(c -> c.getName() == null || !historicallyExcluded.contains(
                            c.getName().toLowerCase(Locale.ROOT)))
                    .max(java.util.Comparator.comparingDouble(
                            c -> c.getRating() != null ? c.getRating() : 0.0));
        } catch (Exception e) {
            log.warn("[ADAPTIVE] Mapbox replacement search failed for '{}': {}", wp.getName(), e.getMessage());
            return Optional.empty();
        }
    }

    private void applyReplacement(AiChatDto.RouteWaypoint wp, PoiResult r) {
        wp.setName(r.getName());
        wp.setLatitude(r.getLat());
        wp.setLongitude(r.getLon());
        if (r.getCategory() != null) wp.setCategory(r.getCategory());
        wp.setUnavailable(null); // new stop is available
        wp.setArrivalTimeLocal(null);
        wp.setDepartureTimeLocal(null);
        wp.setTravelFromPreviousMin(null);
    }

    private void renumberOrders(List<AiChatDto.RouteWaypoint> waypoints) {
        int order = 1;
        for (AiChatDto.RouteWaypoint wp : waypoints) {
            wp.setOrder(order++);
        }
    }

    private AdjustmentResult.WaypointActionSummary summaryOf(
            String name, int day, String action, String replacement) {
        return AdjustmentResult.WaypointActionSummary.builder()
                .poiName(name)
                .day(day)
                .action(action)
                .replacementName(replacement)
                .build();
    }

    private void recordMetric(String action) {
        meterRegistry.ifAvailable(mr ->
                mr.counter("itinerary.adjustment.waypoint",
                        Tags.of("action", action)).increment());
    }
}
