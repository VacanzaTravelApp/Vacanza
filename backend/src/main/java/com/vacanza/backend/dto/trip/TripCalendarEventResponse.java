package com.vacanza.backend.dto.trip;

import java.time.LocalDate;
import java.util.UUID;

public record TripCalendarEventResponse(
        UUID eventId,
        UUID routeId,
        String title,
        String destination,
        LocalDate eventDate,
        int totalDays,
        int itineraryDay
) {}
