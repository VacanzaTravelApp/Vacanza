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
        List<String> categoryKeys
) {
}
