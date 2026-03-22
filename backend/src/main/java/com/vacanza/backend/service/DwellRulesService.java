package com.vacanza.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import com.vacanza.backend.integration.ai.UserProfileForAi;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.InputStream;
import java.util.Locale;

/**
 * Loads {@code dwell_rules.yaml} and resolves dwell minutes from category + trip pace + visit style.
 * Dynamic bbox/density modifiers are not applied yet (no POI metadata on waypoints).
 */
@Slf4j
@Service
public class DwellRulesService {

    private static final String RESOURCE = "dwell_rules.yaml";

    private final ObjectMapper yamlMapper = new ObjectMapper(new YAMLFactory());

    private JsonNode dwellRulesRoot;
    private int globalMin = 10;
    private int globalMax = 480;
    private int defaultParkingToDoorMin = 5;
    private int entranceFrictionTicketTypical = 15;

    /**
     * Package-visible for tests; also invoked by Spring after construction.
     */
    @PostConstruct
    public void load() {
        ClassPathResource res = new ClassPathResource(RESOURCE);
        if (!res.exists()) {
            log.warn("Missing {}; dwell fallback will use legacy heuristics", RESOURCE);
            return;
        }
        try (InputStream in = res.getInputStream()) {
            JsonNode file = yamlMapper.readTree(in);
            dwellRulesRoot = file.get("dwell_rules");
            if (dwellRulesRoot == null || dwellRulesRoot.isMissingNode()) {
                log.warn("YAML has no dwell_rules root");
                dwellRulesRoot = null;
                return;
            }
            JsonNode clamps = dwellRulesRoot.get("global_clamps");
            if (clamps != null) {
                globalMin = clamps.path("min_minutes").asInt(10);
                globalMax = clamps.path("max_minutes").asInt(480);
            }
            JsonNode logistics = dwellRulesRoot.get("logistics_buffers");
            if (logistics != null) {
                defaultParkingToDoorMin = logistics.path("default_parking_to_door_min").asInt(5);
                entranceFrictionTicketTypical = logistics.path("entrance_friction_min")
                        .path("ticket_typical_true").asInt(15);
            }
            log.info("Loaded {} (version {})", RESOURCE, dwellRulesRoot.path("version").asInt());
        } catch (Exception e) {
            log.error("Failed to load {}", RESOURCE, e);
            dwellRulesRoot = null;
        }
    }

    /**
     * Dwell minutes when AI did not set estimated_duration_min. Uses matrix + optional ticket/parking buffer.
     */
    public int resolveDwellMinutes(String category, UserProfileForAi profile) {
        if (dwellRulesRoot == null) {
            return legacyFallbackDwell(category, profile);
        }
        String pace = mapTripPaceToItineraryPace(profile);
        String style = resolveVisitStyle(profile);
        JsonNode rule = findCategoryRule(category);
        if (rule == null) {
            rule = findRuleById("default_unknown");
        }
        if (rule == null) {
            return legacyFallbackDwell(category, profile);
        }
        int base = matrixCell(rule, pace, style);
        int extra = logisticsExtraMinutes(rule);
        return clamp(base + extra);
    }

    private static String mapTripPaceToItineraryPace(UserProfileForAi profile) {
        if (profile == null || profile.getTripPace() == null || profile.getTripPace().isBlank()) {
            return "BALANCED_DAY";
        }
        return switch (profile.getTripPace().trim().toUpperCase(Locale.ROOT)) {
            case "SLOW" -> "RELAXED_DAY";
            case "FAST" -> "FAST_DAY";
            default -> "BALANCED_DAY";
        };
    }

    /**
     * Visit style is not stored in DB yet; derive a reasonable default from activity level.
     */
    private static String resolveVisitStyle(UserProfileForAi profile) {
        if (profile == null || profile.getActivityLevel() == null || profile.getActivityLevel().isBlank()) {
            return "PHOTO_PASS";
        }
        return switch (profile.getActivityLevel().trim().toUpperCase(Locale.ROOT)) {
            case "LOW" -> "DEPTH_SEEKER";
            case "HIGH" -> "PHOTO_PASS";
            default -> "PHOTO_PASS";
        };
    }

    private JsonNode findCategoryRule(String category) {
        String norm = normalizeCategoryToken(category);
        if (norm.isEmpty()) {
            return null;
        }
        JsonNode categories = dwellRulesRoot.get("categories");
        if (categories == null || !categories.isArray()) {
            return null;
        }
        // Pass 1: exact token match
        for (JsonNode c : categories) {
            if ("default_unknown".equals(c.path("id").asText())) {
                continue;
            }
            for (JsonNode m : c.path("match")) {
                if (!m.isTextual()) {
                    continue;
                }
                String token = normalizeCategoryToken(m.asText());
                if (!token.isEmpty() && norm.equals(token)) {
                    return c;
                }
            }
        }
        // Pass 2: substring (longer tokens first would be better; order in YAML puts specific rules first)
        for (JsonNode c : categories) {
            if ("default_unknown".equals(c.path("id").asText())) {
                continue;
            }
            for (JsonNode m : c.path("match")) {
                if (!m.isTextual()) {
                    continue;
                }
                String token = normalizeCategoryToken(m.asText());
                if (token.length() >= 3 && norm.contains(token)) {
                    return c;
                }
            }
        }
        return null;
    }

    private JsonNode findRuleById(String id) {
        JsonNode categories = dwellRulesRoot.get("categories");
        if (categories == null || !categories.isArray()) {
            return null;
        }
        for (JsonNode c : categories) {
            if (id.equals(c.path("id").asText())) {
                return c;
            }
        }
        return null;
    }

    private int matrixCell(JsonNode categoryRule, String pace, String style) {
        JsonNode matrix = categoryRule.get("minutes_by_pace_and_style");
        if (matrix == null) {
            return 55;
        }
        JsonNode paceNode = matrix.get(pace);
        if (paceNode != null && paceNode.has(style)) {
            int v = paceNode.path(style).asInt(-1);
            if (v > 0) {
                return v;
            }
        }
        // Fallback: BALANCED_DAY + same style, then BALANCED + PHOTO_PASS
        JsonNode balanced = matrix.get("BALANCED_DAY");
        if (balanced != null && balanced.has(style)) {
            int v = balanced.path(style).asInt(-1);
            if (v > 0) {
                return v;
            }
        }
        if (balanced != null) {
            int v = balanced.path("PHOTO_PASS").asInt(-1);
            if (v > 0) {
                return v;
            }
        }
        return 55;
    }

    private int logisticsExtraMinutes(JsonNode categoryRule) {
        JsonNode attrs = categoryRule.get("attributes");
        if (attrs == null || !attrs.has("ticket_typical") || attrs.get("ticket_typical").isNull()) {
            return 0;
        }
        if (!attrs.get("ticket_typical").asBoolean(false)) {
            return 0;
        }
        return entranceFrictionTicketTypical + defaultParkingToDoorMin;
    }

    private int clamp(int minutes) {
        return Math.max(globalMin, Math.min(globalMax, minutes));
    }

    private static String normalizeCategoryToken(String c) {
        if (c == null) {
            return "";
        }
        return c.toLowerCase(Locale.ROOT).replace('-', '_').trim();
    }

    /** Legacy behavior from former RouteTimelineService.categoryFallbackDwell when YAML is absent. */
    private static int legacyFallbackDwell(String category, UserProfileForAi profile) {
        String c = category == null ? "" : category.toLowerCase(Locale.ROOT);
        int base;
        if (c.contains("museum") || c.contains("art_gallery") || c.contains("gallery")) {
            base = 95;
        } else if (c.contains("historic") || c.contains("monument") || c.contains("palace")
                || c.contains("ruins") || c.contains("landmark")) {
            base = 70;
        } else if (c.contains("park") || c.contains("neighborhood")) {
            base = 55;
        } else if (c.contains("restaurant") || c.contains("food") || c.contains("market")) {
            base = 75;
        } else if (c.contains("cafe") || c.contains("coffee")) {
            base = 40;
        } else if (c.contains("church") || c.contains("mosque") || c.contains("worship")) {
            base = 45;
        } else {
            base = 55;
        }
        double mult = 1.0;
        if (profile != null && profile.getTripPace() != null) {
            switch (profile.getTripPace().trim().toUpperCase(Locale.ROOT)) {
                case "SLOW" -> mult = 1.12;
                case "FAST" -> mult = 0.88;
                default -> {
                }
            }
        }
        return Math.max(25, (int) Math.round(base * mult));
    }
}
