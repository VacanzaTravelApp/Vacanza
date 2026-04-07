package com.vacanza.backend.dto.request;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import java.util.List;

/**
 * Ingest for user POI / category feedback (thumbs, remove).
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public record PoiFeedbackEventRequestDTO(
        String eventType,
        String mapboxId,
        String foursquareId,
        List<String> categoryKeys,
        /** When {@code foursquareId}/{@code mapboxId} are absent, anchors POI feedback to name + coordinates (AI waypoints / map). */
        String waypointName,
        Double latitude,
        Double longitude
) {
}
