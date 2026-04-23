package com.vacanza.backend.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vacanza.backend.entity.AiRoute;
import com.vacanza.backend.entity.TripCalendarEvent;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.integration.ai.AiChatDto;
import com.vacanza.backend.repo.TripCalendarEventRepository;
import com.vacanza.backend.util.IcsBuilder;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Generates RFC 5545 (iCalendar / .ics) files from Vacanza trip calendar data.
 * <p>
 * Each POI visit (waypoint) in the route becomes a VEVENT with real clock-time
 * boundaries, a 30-minute VALARM reminder, geo-coordinates, and a deterministic
 * UID for idempotent re-import.
 * </p>
 *
 * @see <a href="https://datatracker.ietf.org/doc/html/rfc5545">RFC 5545</a>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class IcsExportService {

    private static final String CRLF = "\r\n";
    private static final DateTimeFormatter HH_MM = DateTimeFormatter.ofPattern("HH:mm");
    private static final String PRODID = "-//Vacanza//Trip Calendar//EN";

    private final TripCalendarEventRepository calendarRepo;
    private final AiRouteService aiRouteService;
    private final RouteTimelineService routeTimelineService;
    private final ObjectMapper objectMapper;

    // ── Public API ──────────────────────────────────────────────────────────

    /**
     * Export all calendar events for a specific route as an ICS byte array.
     *
     * @throws ResponseStatusException 404 if route not found
     */
    @Transactional(readOnly = true)
    public byte[] exportRouteToIcs(User user, UUID routeId) {
        AiRoute route = aiRouteService.getRoute(routeId, user)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Route not found"));

        List<TripCalendarEvent> events = calendarRepo.findByUserAndAiRouteOrderByEventDateAsc(user, route);
        if (events.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                    "No calendar events found for this route. Add the route to your calendar first.");
        }

        AiChatDto.RouteData routeData = parseAndEnrich(route);
        String calName = route.getTitle() + " — Vacanza";
        String ics = buildVCalendar(calName, events, routeData);

        log.info("Exported ICS for route {} ({} events, {} VEVENTs, {} bytes)",
                routeId, events.size(), countVEvents(ics), ics.length());
        return ics.getBytes(StandardCharsets.UTF_8);
    }

    /**
     * Export all calendar events in a given month as a single ICS byte array.
     */
    @Transactional(readOnly = true)
    public byte[] exportMonthToIcs(User user, int year, int month) {
        LocalDate start = LocalDate.of(year, month, 1);
        LocalDate end = start.withDayOfMonth(start.lengthOfMonth());

        List<TripCalendarEvent> events = calendarRepo
                .findByUserAndEventDateBetweenOrderByEventDateAsc(user, start, end);

        // Group by route, parse each route once
        Map<UUID, List<TripCalendarEvent>> byRoute = events.stream()
                .collect(Collectors.groupingBy(e -> e.getAiRoute().getRouteId(), LinkedHashMap::new, Collectors.toList()));

        Map<UUID, AiChatDto.RouteData> routeDataCache = new HashMap<>();
        for (var entry : byRoute.entrySet()) {
            AiRoute route = entry.getValue().get(0).getAiRoute();
            routeDataCache.put(entry.getKey(), parseAndEnrich(route));
        }

        String calName = year + "-" + String.format("%02d", month) + " Trips — Vacanza";
        String ics = buildVCalendarMultiRoute(calName, byRoute, routeDataCache);

        log.info("Exported monthly ICS for {}-{} ({} events, {} bytes)", year, month, events.size(), ics.length());
        return ics.getBytes(StandardCharsets.UTF_8);
    }

    // ── ICS document assembly ───────────────────────────────────────────────

    private String buildVCalendar(String calName, List<TripCalendarEvent> events,
                                  AiChatDto.RouteData routeData) {
        StringBuilder sb = new StringBuilder(4096);
        appendCalendarHeader(sb, calName);

        for (TripCalendarEvent event : events) {
            int dayNum = event.getItineraryDay() != null ? event.getItineraryDay() : 1;
            AiChatDto.DayPlan dayPlan = findDayPlan(routeData, dayNum);
            appendVEventsForDay(sb, event, dayPlan);
        }

        sb.append("END:VCALENDAR").append(CRLF);
        return sb.toString();
    }

    private String buildVCalendarMultiRoute(String calName,
                                            Map<UUID, List<TripCalendarEvent>> byRoute,
                                            Map<UUID, AiChatDto.RouteData> routeDataCache) {
        StringBuilder sb = new StringBuilder(8192);
        appendCalendarHeader(sb, calName);

        for (var entry : byRoute.entrySet()) {
            AiChatDto.RouteData routeData = routeDataCache.get(entry.getKey());
            for (TripCalendarEvent event : entry.getValue()) {
                int dayNum = event.getItineraryDay() != null ? event.getItineraryDay() : 1;
                AiChatDto.DayPlan dayPlan = findDayPlan(routeData, dayNum);
                appendVEventsForDay(sb, event, dayPlan);
            }
        }

        sb.append("END:VCALENDAR").append(CRLF);
        return sb.toString();
    }

    private void appendCalendarHeader(StringBuilder sb, String calName) {
        sb.append("BEGIN:VCALENDAR").append(CRLF);
        sb.append("VERSION:2.0").append(CRLF);
        appendFolded(sb, "PRODID:" + PRODID);
        sb.append("CALSCALE:GREGORIAN").append(CRLF);
        sb.append("METHOD:PUBLISH").append(CRLF);
        appendFolded(sb, "X-WR-CALNAME:" + IcsBuilder.escapeText(calName));
    }

    // ── VEVENT generation ───────────────────────────────────────────────────

    private void appendVEventsForDay(StringBuilder sb, TripCalendarEvent event,
                                     AiChatDto.DayPlan dayPlan) {
        LocalDate eventDate = event.getEventDate();

        if (dayPlan == null || dayPlan.getWaypoints() == null || dayPlan.getWaypoints().isEmpty()) {
            // Fallback: single all-day event
            appendAllDayEvent(sb, event, eventDate);
            return;
        }

        List<AiChatDto.RouteWaypoint> waypoints = dayPlan.getWaypoints().stream()
                .sorted(Comparator.comparingInt(w -> w.getOrder() > 0 ? w.getOrder() : Integer.MAX_VALUE))
                .toList();

        for (AiChatDto.RouteWaypoint wp : waypoints) {
            appendWaypointEvent(sb, event, eventDate, wp, dayPlan);
        }
    }

    private void appendWaypointEvent(StringBuilder sb, TripCalendarEvent event,
                                     LocalDate eventDate, AiChatDto.RouteWaypoint wp,
                                     AiChatDto.DayPlan dayPlan) {
        LocalTime arrival = parseTime(wp.getArrivalTimeLocal());
        LocalTime departure = parseTime(wp.getDepartureTimeLocal());

        // If no parsed times, try to fall back to day boundaries, or use all-day
        if (arrival == null || departure == null) {
            appendAllDayEvent(sb, event, eventDate, wp);
            return;
        }

        sb.append("BEGIN:VEVENT").append(CRLF);
        sb.append("DTSTART:").append(IcsBuilder.formatDateTime(eventDate, arrival)).append(CRLF);
        sb.append("DTEND:").append(IcsBuilder.formatDateTime(eventDate, departure)).append(CRLF);
        appendFolded(sb, "SUMMARY:" + IcsBuilder.escapeText(wp.getName()));
        appendFolded(sb, "DESCRIPTION:" + buildDescription(wp, dayPlan));
        if (wp.getName() != null) {
            appendFolded(sb, "LOCATION:" + IcsBuilder.escapeText(wp.getName()));
        }
        if (wp.getLatitude() != null && wp.getLongitude() != null) {
            sb.append("GEO:").append(wp.getLatitude()).append(";").append(wp.getLongitude()).append(CRLF);
        }
        sb.append("UID:").append(IcsBuilder.generateUid(event.getEventId(), wp.getOrder())).append(CRLF);
        sb.append("DTSTAMP:").append(formatInstant(event.getCreatedAt())).append(CRLF);

        // 30-minute reminder
        appendValarm(sb, wp.getName());

        sb.append("END:VEVENT").append(CRLF);
    }

    private void appendAllDayEvent(StringBuilder sb, TripCalendarEvent event, LocalDate eventDate) {
        appendAllDayEvent(sb, event, eventDate, null);
    }

    private void appendAllDayEvent(StringBuilder sb, TripCalendarEvent event,
                                   LocalDate eventDate, AiChatDto.RouteWaypoint wp) {
        String title = wp != null && wp.getName() != null
                ? wp.getName()
                : event.getAiRoute().getTitle() + " — Day " + (event.getItineraryDay() != null ? event.getItineraryDay() : 1);
        int order = wp != null ? wp.getOrder() : 0;

        sb.append("BEGIN:VEVENT").append(CRLF);
        sb.append("DTSTART;VALUE=DATE:").append(IcsBuilder.formatDate(eventDate)).append(CRLF);
        sb.append("DTEND;VALUE=DATE:").append(IcsBuilder.formatDate(eventDate.plusDays(1))).append(CRLF);
        appendFolded(sb, "SUMMARY:" + IcsBuilder.escapeText(title));
        if (wp != null && wp.getDescription() != null) {
            appendFolded(sb, "DESCRIPTION:" + IcsBuilder.escapeText(wp.getDescription()));
        }
        if (wp != null && wp.getLatitude() != null && wp.getLongitude() != null) {
            sb.append("GEO:").append(wp.getLatitude()).append(";").append(wp.getLongitude()).append(CRLF);
        }
        sb.append("UID:").append(IcsBuilder.generateUid(event.getEventId(), order)).append(CRLF);
        sb.append("DTSTAMP:").append(formatInstant(event.getCreatedAt())).append(CRLF);
        appendValarm(sb, title);
        sb.append("END:VEVENT").append(CRLF);
    }

    private void appendValarm(StringBuilder sb, String eventName) {
        sb.append("BEGIN:VALARM").append(CRLF);
        sb.append("TRIGGER:-PT30M").append(CRLF);
        sb.append("ACTION:DISPLAY").append(CRLF);
        appendFolded(sb, "DESCRIPTION:" + IcsBuilder.escapeText("Upcoming: " + (eventName != null ? eventName : "Vacanza Trip")));
        sb.append("END:VALARM").append(CRLF);
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    private AiChatDto.RouteData parseAndEnrich(AiRoute route) {
        try {
            AiChatDto.RouteData data = objectMapper.readValue(route.getRouteJson(), AiChatDto.RouteData.class);
            routeTimelineService.enrichTimeline(data);
            return data;
        } catch (Exception e) {
            log.warn("Failed to parse route JSON for route {}: {}", route.getRouteId(), e.getMessage());
            return null;
        }
    }

    private AiChatDto.DayPlan findDayPlan(AiChatDto.RouteData routeData, int dayNum) {
        if (routeData == null || routeData.getDays() == null) {
            return null;
        }
        return routeData.getDays().stream()
                .filter(d -> d.getDay() == dayNum)
                .findFirst()
                .orElse(null);
    }

    private String buildDescription(AiChatDto.RouteWaypoint wp, AiChatDto.DayPlan dayPlan) {
        StringBuilder desc = new StringBuilder();
        if (wp.getDescription() != null && !wp.getDescription().isBlank()) {
            desc.append(IcsBuilder.escapeText(wp.getDescription()));
        }
        if (wp.getCategory() != null) {
            if (desc.length() > 0) desc.append("\\n");
            desc.append("Category: ").append(IcsBuilder.escapeText(wp.getCategory()));
        }
        if (wp.getEstimatedDurationMin() != null && wp.getEstimatedDurationMin() > 0) {
            if (desc.length() > 0) desc.append("\\n");
            desc.append("Duration: ~").append(wp.getEstimatedDurationMin()).append(" min");
        }
        if (dayPlan != null && dayPlan.getTitle() != null) {
            if (desc.length() > 0) desc.append("\\n");
            desc.append("Day: ").append(IcsBuilder.escapeText(dayPlan.getTitle()));
        }
        return desc.toString();
    }

    private static LocalTime parseTime(String timeStr) {
        if (timeStr == null || timeStr.isBlank()) {
            return null;
        }
        try {
            return LocalTime.parse(timeStr.trim(), HH_MM);
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    private static String formatInstant(Instant instant) {
        if (instant == null) {
            instant = Instant.now();
        }
        // DTSTAMP must be UTC: YYYYMMDDTHHMMSSZ
        return instant.toString()
                .replace("-", "")
                .replace(":", "")
                .replaceFirst("\\..*", ""); // remove fractional seconds, keep trailing Z
    }

    private void appendFolded(StringBuilder sb, String line) {
        sb.append(IcsBuilder.foldLine(line)).append(CRLF);
    }

    private static int countVEvents(String ics) {
        int count = 0;
        int idx = 0;
        while ((idx = ics.indexOf("BEGIN:VEVENT", idx)) != -1) {
            count++;
            idx++;
        }
        return count;
    }
}
