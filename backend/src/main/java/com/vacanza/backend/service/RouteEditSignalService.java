package com.vacanza.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vacanza.backend.entity.AiRoute;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.UserInteraction;
import com.vacanza.backend.entity.enums.InteractionType;
import com.vacanza.backend.repo.UserInteractionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Extracts preference signals from Turn3 chat edits by diffing the
 * parent route against the newly saved route.
 *
 * <p>When a user removes POIs of a given category (e.g. drops 3 museums) a
 * {@code ROUTE_EDIT_REMOVE} interaction is recorded for that category.
 * When POIs are added, a {@code ROUTE_EDIT_ADD} interaction is recorded.
 * {@link BehaviorAnalysisService} uses these signals with stronger weights
 * than passive POI views, since an explicit edit is a direct preference signal.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class RouteEditSignalService {

    private final ObjectMapper objectMapper;
    private final UserInteractionRepository interactionRepository;
    private final BehaviorAnalysisService behaviorAnalysisService;

    /**
     * Diffs {@code parentRoute} vs {@code newRoute}, saves interaction rows for
     * each category that was added or removed, then triggers both global and
     * destination-specific preference analysis.
     */
    @Transactional
    public void processEditSignals(User user, AiRoute parentRoute, AiRoute newRoute) {
        try {
            String destination = normalizeDestination(newRoute.getDestination());
            Map<String, Integer> parentCounts = extractCategoryCounts(parentRoute.getRouteJson());
            Map<String, Integer> newCounts    = extractCategoryCounts(newRoute.getRouteJson());

            List<UserInteraction> signals = buildSignals(user, parentCounts, newCounts, destination);

            if (signals.isEmpty()) {
                log.debug("[EditSignal] No category changes detected for user {}", user.getUserId());
                return;
            }

            interactionRepository.saveAll(signals);
            log.info("[EditSignal] Saved {} edit signal(s) for user {} destination='{}' (route v{} → v{})",
                    signals.size(), user.getUserId(), destination,
                    parentRoute.getVersion(), newRoute.getVersion());

            // Global analysis: all interactions across all destinations
            behaviorAnalysisService.analyzeAndSavePreferences(user);

            // Destination-specific analysis: only signals for this destination
            // Saves as "category_preference:istanbul" so it can override the global
            // preference when the user plans a trip to the same city again.
            if (destination != null) {
                behaviorAnalysisService.analyzeAndSaveDestinationPreferences(user, destination);
            }

        } catch (Exception e) {
            // Non-blocking: a diffing failure must never break the chat response
            log.warn("[EditSignal] Failed to process edit signals (non-blocking): {}", e.getMessage());
        }
    }

    private String normalizeDestination(String raw) {
        if (raw == null || raw.isBlank()) return null;
        return raw.trim().toLowerCase(java.util.Locale.ROOT);
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    /**
     * Parses route JSON and returns a map of {category → waypoint count}.
     * Silently skips waypoints that have no "category" field.
     */
    private Map<String, Integer> extractCategoryCounts(String routeJson) throws Exception {
        Map<String, Integer> counts = new HashMap<>();
        JsonNode root = objectMapper.readTree(routeJson);
        JsonNode days = root.path("days");
        if (!days.isArray()) return counts;

        for (JsonNode day : days) {
            JsonNode waypoints = day.path("waypoints");
            if (!waypoints.isArray()) continue;
            for (JsonNode wp : waypoints) {
                String category = wp.path("category").asText(null);
                if (category != null && !category.isBlank()) {
                    counts.merge(category.toLowerCase().trim(), 1, Integer::sum);
                }
            }
        }
        return counts;
    }

    /**
     * Builds {@link UserInteraction} rows for each category whose count changed.
     * One row is saved per unit of change so that existing weight-based queries
     * in {@link UserInteractionRepository} count them naturally.
     */
    private List<UserInteraction> buildSignals(User user,
                                               Map<String, Integer> parentCounts,
                                               Map<String, Integer> newCounts,
                                               String destination) {
        List<UserInteraction> signals = new ArrayList<>();

        for (String category : union(parentCounts, newCounts)) {
            int before = parentCounts.getOrDefault(category, 0);
            int after  = newCounts.getOrDefault(category, 0);
            int delta  = after - before;

            if (delta == 0) continue;

            InteractionType type = delta > 0 ? InteractionType.ROUTE_EDIT_ADD
                                             : InteractionType.ROUTE_EDIT_REMOVE;
            int count = Math.abs(delta);

            // Include destination so preferences can be resolved per-city later
            Map<String, Object> metadata = destination != null
                    ? Map.of("category", category, "destination", destination)
                    : Map.of("category", category);

            for (int i = 0; i < count; i++) {
                signals.add(UserInteraction.builder()
                        .user(user)
                        .interactionType(type)
                        .metadata(metadata)
                        .build());
            }

            log.debug("[EditSignal] category='{}' destination='{}' delta={} → {} x{}",
                    category, destination, delta, type, count);
        }

        return signals;
    }

    private java.util.Set<String> union(Map<String, Integer> a, Map<String, Integer> b) {
        java.util.Set<String> keys = new java.util.HashSet<>(a.keySet());
        keys.addAll(b.keySet());
        return keys;
    }
}
