package com.vacanza.backend.dto.adjustment;

import lombok.Builder;
import lombok.Data;

import java.util.UUID;

/**
 * SSE payload pushed to the client when an itinerary adjustment completes.
 * Serialised as JSON in the {@code data:} field of the event stream.
 */
@Data
@Builder
public class RouteUpdatedNotification {

    private UUID originalRouteId;
    private UUID newRouteId;
    private int version;
    private String triggerType;
    private String userMessage;
    private boolean success;
}
