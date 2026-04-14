package com.vacanza.backend.scheduler;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vacanza.backend.dto.adjustment.AdjustmentTriggerRequest;
import com.vacanza.backend.dto.weather.DailyWeatherSummary;
import com.vacanza.backend.entity.AiRoute;
import com.vacanza.backend.entity.enums.AdjustmentSeverity;
import com.vacanza.backend.entity.enums.AdjustmentTriggerType;
import com.vacanza.backend.integration.ai.AiChatDto;
import com.vacanza.backend.repo.AiRouteRepository;
import com.vacanza.backend.service.ItineraryAdjustmentService;
import com.vacanza.backend.service.WeatherService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;

/**
 * Periodically checks weather for upcoming trips and triggers adaptive adjustments
 * when severe conditions are forecast.
 *
 * <p>Runs every 30 minutes. For each route whose trip starts within the next 48 hours,
 * it fetches a 3-day forecast and evaluates WMO weather codes.
 *
 * <h3>Severe-weather WMO codes</h3>
 * <ul>
 *   <li>65, 67         — Heavy rain / freezing rain → HIGH</li>
 *   <li>71–77          — Snow → MEDIUM</li>
 *   <li>80–82, 85, 86  — Heavy showers → HIGH</li>
 *   <li>95–99          — Thunderstorm → CRITICAL</li>
 * </ul>
 *
 * <p>Adjustments are idempotent: the same weather alert for the same route on the same
 * calendar day will not trigger a second replan.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class WeatherAlertScheduler {

    /** Check every 30 minutes. */
    private static final long INTERVAL_MS = 30 * 60 * 1000L;

    /** Only process routes starting within the next 48 hours. */
    private static final int LOOKAHEAD_DAYS = 2;

    /** Max routes per scheduler run (prevents thundering-herd on cold start). */
    private static final int MAX_ROUTES_PER_RUN = 50;

    private final AiRouteRepository routeRepository;
    private final WeatherService weatherService;
    private final ItineraryAdjustmentService adjustmentService;
    private final ObjectMapper objectMapper;

    @Scheduled(fixedDelay = INTERVAL_MS)
    public void checkWeatherAlerts() {
        LocalDate today = LocalDate.now();
        LocalDate horizon = today.plusDays(LOOKAHEAD_DAYS);

        log.debug("[WEATHER_SCHEDULER] Checking weather alerts for trips starting {} – {}", today, horizon);

        // Fetch recent routes (version 1 only — latest originals, not derived versions)
        // Use a simple findAll with limit as a pragmatic first pass.
        // In production this would be a dedicated query filtering by trip_start_date.
        List<AiRoute> candidates = routeRepository.findAll(PageRequest.of(0, MAX_ROUTES_PER_RUN))
                .getContent()
                .stream()
                .filter(r -> r.getVersion() == 1)
                .toList();

        for (AiRoute route : candidates) {
            try {
                processRoute(route, today, horizon);
            } catch (Exception e) {
                log.warn("[WEATHER_SCHEDULER] Error processing route {}: {}", route.getRouteId(), e.getMessage());
            }
        }
    }

    // ── Internal ─────────────────────────────────────────────────────────────

    private void processRoute(AiRoute route, LocalDate today, LocalDate horizon) {
        AiChatDto.RouteData routeData;
        try {
            routeData = objectMapper.readValue(route.getRouteJson(), AiChatDto.RouteData.class);
        } catch (Exception e) {
            return;
        }

        // Only process routes with an explicit trip_start_date within the lookahead window
        if (routeData.getTripStartDate() == null) return;
        LocalDate tripStart;
        try {
            tripStart = LocalDate.parse(routeData.getTripStartDate());
        } catch (DateTimeParseException e) {
            return;
        }
        if (tripStart.isBefore(today) || tripStart.isAfter(horizon)) return;

        // Get coordinates from the first waypoint of Day 1
        double[] coords = firstWaypointCoords(routeData);
        if (coords == null) return;

        List<DailyWeatherSummary> forecast = weatherService.getDailyForecast(
                coords[0], coords[1], LOOKAHEAD_DAYS + 1);

        if (forecast == null || forecast.isEmpty()) return;

        for (DailyWeatherSummary day : forecast) {
            if (day.weatherCode() == null) continue;
            AdjustmentSeverity severity = severityFor(day.weatherCode());
            if (severity == null) continue;

            String reason = buildWeatherReason(day);
            log.info("[WEATHER_SCHEDULER] Severe weather ({}) on {} for route {} — triggering {} adjustment",
                    day.weatherCode(), day.date(), route.getRouteId(), severity);

            AdjustmentTriggerRequest req = new AdjustmentTriggerRequest();
            req.setTriggerType(AdjustmentTriggerType.WEATHER_ALERT);
            req.setSeverity(severity);
            req.setReason(reason);
            // affectedPoiName = null → all outdoor sightseeing stops are candidates

            adjustmentService.triggerAsync(route.getRouteId(), route.getUser(), req);
            // Only one alert per route per run to avoid flooding
            return;
        }
    }

    private static double[] firstWaypointCoords(AiChatDto.RouteData routeData) {
        if (routeData.getDays() == null || routeData.getDays().isEmpty()) return null;
        for (AiChatDto.DayPlan day : routeData.getDays()) {
            if (day.getWaypoints() == null) continue;
            for (AiChatDto.RouteWaypoint wp : day.getWaypoints()) {
                if (wp.getLatitude() != null && wp.getLongitude() != null) {
                    return new double[]{wp.getLatitude(), wp.getLongitude()};
                }
            }
        }
        return null;
    }

    /**
     * Returns the adjustment severity for a WMO code, or {@code null} if conditions
     * are not severe enough to trigger an adjustment.
     *
     * @see <a href="https://open-meteo.com/en/docs">Open-Meteo WMO codes</a>
     */
    private static AdjustmentSeverity severityFor(int code) {
        if (code >= 95) return AdjustmentSeverity.CRITICAL;  // thunderstorm
        if (code >= 80) return AdjustmentSeverity.HIGH;       // heavy showers
        if (code == 65 || code == 67) return AdjustmentSeverity.HIGH;  // heavy rain / freezing
        if (code >= 71 && code <= 77) return AdjustmentSeverity.MEDIUM; // snow
        return null; // not severe
    }

    private static String buildWeatherReason(DailyWeatherSummary day) {
        String condition = wmoDescription(day.weatherCode());
        String temp = day.tempMaxCelsius() != null
                ? String.format("%.0f°C", day.tempMaxCelsius())
                : "unknown temperature";
        return String.format("%s on %s (%s)", condition, day.date(), temp);
    }

    private static String wmoDescription(int code) {
        if (code >= 95) return "Thunderstorm";
        if (code >= 85) return "Heavy snow showers";
        if (code >= 80) return "Heavy rain showers";
        if (code == 67) return "Freezing rain";
        if (code == 65) return "Heavy rain";
        if (code >= 71) return "Snowfall";
        return "Severe weather (code " + code + ")";
    }
}
