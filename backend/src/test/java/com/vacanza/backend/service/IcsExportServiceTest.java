package com.vacanza.backend.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vacanza.backend.entity.AiRoute;
import com.vacanza.backend.entity.TripCalendarEvent;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.integration.ai.AiChatDto;
import com.vacanza.backend.repo.TripCalendarEventRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.LocalDate;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class IcsExportServiceTest {

    @Mock private TripCalendarEventRepository calendarRepo;
    @Mock private AiRouteService aiRouteService;
    @Mock private RouteTimelineService routeTimelineService;
    @Spy  private ObjectMapper objectMapper = new ObjectMapper();

    @InjectMocks
    private IcsExportService icsExportService;

    private User testUser;
    private AiRoute testRoute;
    private UUID routeId;

    @BeforeEach
    void setUp() {
        testUser = new User();
        testUser.setUserId(UUID.randomUUID());

        routeId = UUID.randomUUID();
        testRoute = AiRoute.builder()
                .routeId(routeId)
                .user(testUser)
                .title("Istanbul Discovery")
                .destination("Istanbul")
                .totalDays(2)
                .routeJson(buildRouteJson())
                .build();
    }

    // ── exportRouteToIcs ────────────────────────────────────────────────────

    @Test
    void exportRouteToIcs_singleDay_producesValidVCalendar() {
        testRoute.setTotalDays(1);
        testRoute.setRouteJson(buildSingleDayRouteJson());

        TripCalendarEvent event = buildEvent(1, LocalDate.of(2026, 5, 10));

        when(aiRouteService.getRoute(routeId, testUser)).thenReturn(Optional.of(testRoute));
        when(calendarRepo.findByUserAndAiRouteOrderByEventDateAsc(testUser, testRoute))
                .thenReturn(List.of(event));

        byte[] result = icsExportService.exportRouteToIcs(testUser, routeId);
        String ics = new String(result, StandardCharsets.UTF_8);

        assertTrue(ics.startsWith("BEGIN:VCALENDAR"));
        assertTrue(ics.contains("VERSION:2.0"));
        assertTrue(ics.contains("PRODID:-//Vacanza//Trip Calendar//EN"));
        assertTrue(ics.endsWith("END:VCALENDAR\r\n"));
        assertTrue(ics.contains("BEGIN:VEVENT"));
        assertTrue(ics.contains("END:VEVENT"));
    }

    @Test
    void exportRouteToIcs_multiDay_createsEventsOnConsecutiveDates() {
        TripCalendarEvent day1 = buildEvent(1, LocalDate.of(2026, 5, 10));
        TripCalendarEvent day2 = buildEvent(2, LocalDate.of(2026, 5, 11));

        when(aiRouteService.getRoute(routeId, testUser)).thenReturn(Optional.of(testRoute));
        when(calendarRepo.findByUserAndAiRouteOrderByEventDateAsc(testUser, testRoute))
                .thenReturn(List.of(day1, day2));

        byte[] result = icsExportService.exportRouteToIcs(testUser, routeId);
        String ics = new String(result, StandardCharsets.UTF_8);

        assertTrue(ics.contains("20260510"), "Should contain May 10 date");
        assertTrue(ics.contains("20260511"), "Should contain May 11 date");
    }

    @Test
    void exportRouteToIcs_containsValarm() {
        TripCalendarEvent event = buildEvent(1, LocalDate.of(2026, 5, 10));

        when(aiRouteService.getRoute(routeId, testUser)).thenReturn(Optional.of(testRoute));
        when(calendarRepo.findByUserAndAiRouteOrderByEventDateAsc(testUser, testRoute))
                .thenReturn(List.of(event));

        byte[] result = icsExportService.exportRouteToIcs(testUser, routeId);
        String ics = new String(result, StandardCharsets.UTF_8);

        assertTrue(ics.contains("BEGIN:VALARM"), "Should contain VALARM");
        assertTrue(ics.contains("TRIGGER:-PT30M"), "Should have 30-min trigger");
        assertTrue(ics.contains("ACTION:DISPLAY"), "Should have DISPLAY action");
    }

    @Test
    void exportRouteToIcs_containsGeoCoordinates() {
        TripCalendarEvent event = buildEvent(1, LocalDate.of(2026, 5, 10));

        when(aiRouteService.getRoute(routeId, testUser)).thenReturn(Optional.of(testRoute));
        when(calendarRepo.findByUserAndAiRouteOrderByEventDateAsc(testUser, testRoute))
                .thenReturn(List.of(event));

        byte[] result = icsExportService.exportRouteToIcs(testUser, routeId);
        String ics = new String(result, StandardCharsets.UTF_8);

        assertTrue(ics.contains("GEO:"), "Should contain GEO property");
    }

    @Test
    void exportRouteToIcs_routeNotFound_throws404() {
        when(aiRouteService.getRoute(routeId, testUser)).thenReturn(Optional.empty());

        assertThrows(ResponseStatusException.class,
                () -> icsExportService.exportRouteToIcs(testUser, routeId));
    }

    @Test
    void exportRouteToIcs_noCalendarEvents_throws404() {
        when(aiRouteService.getRoute(routeId, testUser)).thenReturn(Optional.of(testRoute));
        when(calendarRepo.findByUserAndAiRouteOrderByEventDateAsc(testUser, testRoute))
                .thenReturn(Collections.emptyList());

        assertThrows(ResponseStatusException.class,
                () -> icsExportService.exportRouteToIcs(testUser, routeId));
    }

    @Test
    void exportRouteToIcs_invalidRouteJson_producesAllDayFallback() {
        testRoute.setRouteJson("{invalid json!!!}");
        TripCalendarEvent event = buildEvent(1, LocalDate.of(2026, 5, 10));

        when(aiRouteService.getRoute(routeId, testUser)).thenReturn(Optional.of(testRoute));
        when(calendarRepo.findByUserAndAiRouteOrderByEventDateAsc(testUser, testRoute))
                .thenReturn(List.of(event));

        byte[] result = icsExportService.exportRouteToIcs(testUser, routeId);
        String ics = new String(result, StandardCharsets.UTF_8);

        // Should still produce valid VCALENDAR with all-day fallback
        assertTrue(ics.contains("BEGIN:VCALENDAR"));
        assertTrue(ics.contains("DTSTART;VALUE=DATE:"), "Should fall back to all-day event");
    }

    // ── exportMonthToIcs ────────────────────────────────────────────────────

    @Test
    void exportMonthToIcs_emptyMonth_producesValidEmptyCalendar() {
        when(calendarRepo.findByUserAndEventDateBetweenOrderByEventDateAsc(eq(testUser), any(), any()))
                .thenReturn(Collections.emptyList());

        byte[] result = icsExportService.exportMonthToIcs(testUser, 2026, 5);
        String ics = new String(result, StandardCharsets.UTF_8);

        assertTrue(ics.startsWith("BEGIN:VCALENDAR"));
        assertTrue(ics.endsWith("END:VCALENDAR\r\n"));
        assertFalse(ics.contains("BEGIN:VEVENT"), "Empty month should have no VEVENTs");
    }

    @Test
    void exportMonthToIcs_multipleRoutes_allIncluded() {
        UUID route2Id = UUID.randomUUID();
        AiRoute route2 = AiRoute.builder()
                .routeId(route2Id)
                .user(testUser)
                .title("Ankara Trip")
                .destination("Ankara")
                .totalDays(1)
                .routeJson(buildSingleDayRouteJson())
                .build();

        TripCalendarEvent ev1 = buildEvent(1, LocalDate.of(2026, 5, 5));
        TripCalendarEvent ev2 = buildEventForRoute(route2, 1, LocalDate.of(2026, 5, 15));

        when(calendarRepo.findByUserAndEventDateBetweenOrderByEventDateAsc(eq(testUser), any(), any()))
                .thenReturn(List.of(ev1, ev2));

        byte[] result = icsExportService.exportMonthToIcs(testUser, 2026, 5);
        String ics = new String(result, StandardCharsets.UTF_8);

        assertTrue(ics.contains("20260505"), "Should include first route's date");
        assertTrue(ics.contains("20260515"), "Should include second route's date");
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    private TripCalendarEvent buildEvent(int itineraryDay, LocalDate date) {
        return TripCalendarEvent.builder()
                .eventId(UUID.randomUUID())
                .user(testUser)
                .aiRoute(testRoute)
                .eventDate(date)
                .itineraryDay(itineraryDay)
                .createdAt(Instant.now())
                .build();
    }

    private TripCalendarEvent buildEventForRoute(AiRoute route, int itineraryDay, LocalDate date) {
        return TripCalendarEvent.builder()
                .eventId(UUID.randomUUID())
                .user(testUser)
                .aiRoute(route)
                .eventDate(date)
                .itineraryDay(itineraryDay)
                .createdAt(Instant.now())
                .build();
    }

    private String buildRouteJson() {
        return """
                {
                  "title": "Istanbul Discovery",
                  "destination": "Istanbul",
                  "total_days": 2,
                  "days": [
                    {
                      "day": 1,
                      "title": "Historic Peninsula",
                      "day_start_local": "09:00",
                      "waypoints": [
                        {
                          "name": "Hagia Sophia",
                          "description": "A masterpiece of Byzantine architecture",
                          "category": "museum",
                          "day": 1,
                          "order": 1,
                          "latitude": 41.0086,
                          "longitude": 28.9802,
                          "estimated_duration_min": 90,
                          "arrival_time_local": "09:00",
                          "departure_time_local": "10:30"
                        },
                        {
                          "name": "Blue Mosque",
                          "description": "Iconic Ottoman mosque",
                          "category": "landmark",
                          "day": 1,
                          "order": 2,
                          "latitude": 41.0054,
                          "longitude": 28.9768,
                          "estimated_duration_min": 60,
                          "arrival_time_local": "10:45",
                          "departure_time_local": "11:45"
                        }
                      ]
                    },
                    {
                      "day": 2,
                      "title": "Bosphorus & Beyond",
                      "day_start_local": "10:00",
                      "waypoints": [
                        {
                          "name": "Dolmabahce Palace",
                          "description": "Ottoman imperial palace",
                          "category": "museum",
                          "day": 2,
                          "order": 1,
                          "latitude": 41.0391,
                          "longitude": 29.0007,
                          "estimated_duration_min": 120,
                          "arrival_time_local": "10:00",
                          "departure_time_local": "12:00"
                        }
                      ]
                    }
                  ]
                }
                """;
    }

    private String buildSingleDayRouteJson() {
        return """
                {
                  "title": "City Walk",
                  "destination": "Istanbul",
                  "total_days": 1,
                  "days": [
                    {
                      "day": 1,
                      "title": "Quick Tour",
                      "day_start_local": "09:00",
                      "waypoints": [
                        {
                          "name": "Grand Bazaar",
                          "description": "Historic covered market",
                          "category": "market",
                          "day": 1,
                          "order": 1,
                          "latitude": 41.0107,
                          "longitude": 28.9681,
                          "estimated_duration_min": 60,
                          "arrival_time_local": "09:00",
                          "departure_time_local": "10:00"
                        }
                      ]
                    }
                  ]
                }
                """;
    }
}
