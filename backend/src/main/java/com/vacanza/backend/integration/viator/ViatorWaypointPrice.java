package com.vacanza.backend.integration.viator;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * Viator price snapshot for a waypoint / attraction.
 */
public record ViatorWaypointPrice(
        BigDecimal minPrice,
        String currency,
        String productUrl,
        String productTitle,
        Instant fetchedAt
) {
    public static ViatorWaypointPrice empty(Instant fetchedAt) {
        return new ViatorWaypointPrice(null, null, null, null, fetchedAt);
    }

    public boolean hasPrice() {
        return minPrice != null;
    }
}
