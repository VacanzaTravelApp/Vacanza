package com.vacanza.backend.controller;

import com.vacanza.backend.dto.trip.CreateTripCalendarEventRequest;
import com.vacanza.backend.dto.trip.TripCalendarEventResponse;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.security.CurrentUserProvider;
import com.vacanza.backend.service.IcsExportService;
import com.vacanza.backend.service.TripCalendarService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/users/me/trip-calendar")
@RequiredArgsConstructor
public class TripCalendarController {

    private final TripCalendarService tripCalendarService;
    private final IcsExportService icsExportService;
    private final CurrentUserProvider currentUserProvider;

    @GetMapping("/events")
    public ResponseEntity<List<TripCalendarEventResponse>> listEvents(
            @RequestParam int year,
            @RequestParam int month) {
        User user = currentUserProvider.getCurrentUserEntity();
        if (month < 1 || month > 12) {
            return ResponseEntity.badRequest().build();
        }
        return ResponseEntity.ok(tripCalendarService.listForMonth(user, year, month));
    }

    @PostMapping("/events")
    public ResponseEntity<List<TripCalendarEventResponse>> createEvent(@Valid @RequestBody CreateTripCalendarEventRequest body) {
        User user = currentUserProvider.getCurrentUserEntity();
        List<TripCalendarEventResponse> created = tripCalendarService.create(user, body);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @DeleteMapping("/events/{eventId}")
    public ResponseEntity<Void> deleteEvent(@PathVariable UUID eventId) {
        User user = currentUserProvider.getCurrentUserEntity();
        tripCalendarService.delete(user, eventId);
        return ResponseEntity.noContent().build();
    }

    /** Remove this route from the calendar on every day (whole multi-day trip). */
    @DeleteMapping("/events/by-route/{routeId}")
    public ResponseEntity<Void> deleteEventsByRoute(@PathVariable UUID routeId) {
        User user = currentUserProvider.getCurrentUserEntity();
        tripCalendarService.deleteAllForRoute(user, routeId);
        return ResponseEntity.noContent().build();
    }

    // ── ICS Export (FReq7: Smart Calendar Synchronization) ───────────────

    /** Download ICS file for a single route's calendar events. */
    @GetMapping(value = "/export/route/{routeId}", produces = "text/calendar")
    public ResponseEntity<byte[]> exportRouteIcs(@PathVariable UUID routeId) {
        User user = currentUserProvider.getCurrentUserEntity();
        byte[] ics = icsExportService.exportRouteToIcs(user, routeId);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"vacanza-trip.ics\"")
                .contentType(MediaType.parseMediaType("text/calendar; charset=utf-8"))
                .body(ics);
    }

    /** Download ICS file for all calendar events in a given month. */
    @GetMapping(value = "/export/month", produces = "text/calendar")
    public ResponseEntity<byte[]> exportMonthIcs(
            @RequestParam int year, @RequestParam int month) {
        User user = currentUserProvider.getCurrentUserEntity();
        if (month < 1 || month > 12) {
            return ResponseEntity.badRequest().build();
        }
        byte[] ics = icsExportService.exportMonthToIcs(user, year, month);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"vacanza-" + year + "-" + String.format("%02d", month) + ".ics\"")
                .contentType(MediaType.parseMediaType("text/calendar; charset=utf-8"))
                .body(ics);
    }
}
