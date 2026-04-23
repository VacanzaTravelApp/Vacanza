package com.vacanza.backend.dto.response;

import java.time.Instant;

public record SavedPoiDTO(
        String poiKey,
        String name,
        String category,
        Double latitude,
        Double longitude,
        double score,
        Instant updatedAt
) {}
