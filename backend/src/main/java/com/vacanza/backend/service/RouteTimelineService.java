package com.vacanza.backend.service;

import com.vacanza.backend.integration.ai.AiChatDto;
import com.vacanza.backend.integration.ai.UserProfileForAi;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.OptionalDouble;

/**
 * Builds a same-day clock schedule from waypoint order, dwell times, and walking
 * segment durations (Mapbox walking directions, with haversine fallback).
 * Prefers times and dwells from the AI route JSON; falls back to user profile and category heuristics.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class RouteTimelineService {

    private static final DateTimeFormatter HH_MM = DateTimeFormatter.ofPattern("HH:mm");

    /** ~5 km/h walking — minutes ≈ km * 12 */
    private static final double MINUTES_PER_KM_WALK = 12.0;

    private final MapboxDirectionsService mapboxDirectionsService;
    private final DwellRulesService dwellRulesService;

    public void enrichTimeline(AiChatDto.RouteData routeData) {
        enrichTimeline(routeData, null);
    }

    public void enrichTimeline(AiChatDto.RouteData routeData, UserProfileForAi profile) {
        if (routeData == null || routeData.getDays() == null) {
            return;
        }
        for (AiChatDto.DayPlan day : routeData.getDays()) {
            enrichDay(day, profile);
        }
    }

    private void enrichDay(AiChatDto.DayPlan day, UserProfileForAi profile) {
        if (day.getWaypoints() == null || day.getWaypoints().isEmpty()) {
            return;
        }
        List<AiChatDto.RouteWaypoint> sorted = new ArrayList<>(day.getWaypoints());
        sorted.sort(Comparator.comparingInt(w -> w.getOrder() > 0 ? w.getOrder() : Integer.MAX_VALUE));

        LocalTime cursor = resolveDayStart(day, profile);
        day.setDayStartLocal(HH_MM.format(cursor));

        AiChatDto.RouteWaypoint prev = null;
        for (AiChatDto.RouteWaypoint wp : sorted) {
            Integer travelMin = null;
            if (prev != null && hasCoords(prev) && hasCoords(wp)) {
                travelMin = travelMinutesBetween(
                        prev.getLatitude(), prev.getLongitude(),
                        wp.getLatitude(), wp.getLongitude());
                cursor = cursor.plusMinutes(travelMin);
            } else if (prev != null) {
                travelMin = 15;
                cursor = cursor.plusMinutes(travelMin);
            }

            int dwell = dwellMinutes(wp, profile);
            LocalTime arrival = cursor;
            LocalTime departure = arrival.plusMinutes(dwell);

            wp.setTravelFromPreviousMin(travelMin);
            wp.setArrivalTimeLocal(HH_MM.format(arrival));
            wp.setDepartureTimeLocal(HH_MM.format(departure));
            wp.setTimeSlot(resolveTimeSlot(arrival, wp.getCategory()));

            cursor = departure;
            prev = wp;
        }

        if (prev != null && prev.getDepartureTimeLocal() != null) {
            day.setDayEndLocal(prev.getDepartureTimeLocal());
        }
    }

    private static final java.util.Set<String> DINING_CATEGORIES = java.util.Set.of(
            "restaurant", "cafe", "bar", "fast_food", "bakery", "pub",
            "nightclub", "nightlife", "market", "food");

    private static boolean isDiningCategory(String category) {
        if (category == null || category.isBlank()) {
            return false;
        }
        String key = category.trim().toLowerCase(Locale.ROOT);
        return DINING_CATEGORIES.contains(key);
    }

    /**
     * Derive time_slot from the actual computed arrival time AND the POI category.
     * Dining venues get meal-specific labels; sightseeing gets time-of-day labels.
     */
    private static String resolveTimeSlot(LocalTime arrival, String category) {
        int hour = arrival.getHour();
        if (isDiningCategory(category)) {
            if (hour < 11) {
                return "morning";
            }
            if (hour < 14) {
                return "lunch";
            }
            if (hour < 17) {
                return "afternoon";
            }
            if (hour < 21) {
                return "dinner";
            }
            return "night";
        }
        // Sightseeing / non-dining
        if (hour < 12) {
            return "morning";
        }
        if (hour < 17) {
            return "afternoon";
        }
        if (hour < 21) {
            return "evening";
        }
        return "night";
    }

    private static boolean hasCoords(AiChatDto.RouteWaypoint w) {
        return w.getLatitude() != null && w.getLongitude() != null
                && Double.isFinite(w.getLatitude()) && Double.isFinite(w.getLongitude());
    }

    private LocalTime resolveDayStart(AiChatDto.DayPlan day, UserProfileForAi profile) {
        String raw = day.getDayStartLocal();
        if (raw != null && !raw.isBlank()) {
            try {
                return LocalTime.parse(raw.trim(), HH_MM);
            } catch (DateTimeParseException e) {
                log.debug("Invalid day_start_local '{}', using profile default", raw);
            }
        }
        return defaultStartFromProfile(profile);
    }

    /**
     * When the model omits day_start_local, derive from trip pace / activity level.
     */
    private static LocalTime defaultStartFromProfile(UserProfileForAi profile) {
        int hour = 9;
        int minute = 0;
        if (profile != null && profile.getTripPace() != null) {
            switch (profile.getTripPace().trim().toUpperCase(Locale.ROOT)) {
                case "SLOW" -> {
                    hour = 10;
                    minute = 0;
                }
                case "FAST" -> {
                    hour = 8;
                    minute = 30;
                }
                default -> {
                }
            }
        }
        LocalTime t = LocalTime.of(hour, minute);
        if (profile != null && profile.getActivityLevel() != null) {
            switch (profile.getActivityLevel().trim().toUpperCase(Locale.ROOT)) {
                case "LOW" -> t = t.plusMinutes(30);
                case "HIGH" -> t = t.minusMinutes(15);
                default -> {
                }
            }
        }
        return t;
    }

    private int dwellMinutes(AiChatDto.RouteWaypoint wp, UserProfileForAi profile) {
        Integer e = wp.getEstimatedDurationMin();
        if (e != null && e > 0) {
            return e;
        }
        return dwellRulesService.resolveDwellMinutes(wp.getCategory(), profile);
    }

    private int travelMinutesBetween(double lat1, double lon1, double lat2, double lon2) {
        OptionalDouble sec = mapboxDirectionsService.getWalkingDurationSeconds(lat1, lon1, lat2, lon2);
        if (sec.isPresent() && sec.getAsDouble() > 0) {
            int min = (int) Math.ceil(sec.getAsDouble() / 60.0);
            return Math.max(1, min);
        }
        double km = haversineKm(lat1, lon1, lat2, lon2);
        int est = (int) Math.ceil(km * MINUTES_PER_KM_WALK);
        return Math.max(1, est);
    }

    private static double haversineKm(double lat1, double lon1, double lat2, double lon2) {
        final double R = 6371.0;
        double p1 = Math.toRadians(lat1);
        double p2 = Math.toRadians(lat2);
        double dp = Math.toRadians(lat2 - lat1);
        double dl = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dp / 2) * Math.sin(dp / 2)
                + Math.cos(p1) * Math.cos(p2) * Math.sin(dl / 2) * Math.sin(dl / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
}
