package com.vacanza.backend.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.math.BigDecimal;

/**
 * Viator-derived pricing for one route waypoint (partial results allowed).
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record WaypointPricing(
        String waypointName,
        int day,
        int order,
        BigDecimal minPriceUsd,
        String currency,
        String bookingUrl,
        boolean found,
        WaypointPricingStatus status,
        /** Present when {@link #status} is {@link WaypointPricingStatus#PARTNER_UNAVAILABLE} or for extra context. */
        String message
) {
    public static WaypointPricing noName(int day, int order) {
        return new WaypointPricing("", day, order, null, null, null, false, WaypointPricingStatus.NO_MATCH, null);
    }
}
