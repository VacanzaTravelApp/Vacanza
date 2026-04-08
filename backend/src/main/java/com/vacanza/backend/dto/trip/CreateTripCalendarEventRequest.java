package com.vacanza.backend.dto.trip;

import jakarta.validation.constraints.NotNull;

import java.time.LocalDate;
import java.util.UUID;

public record CreateTripCalendarEventRequest(
        @NotNull UUID routeId,
        @NotNull LocalDate eventDate
) {}
