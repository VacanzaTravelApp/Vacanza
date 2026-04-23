package com.vacanza.backend.dto.response;

/**
 * Per-waypoint outcome for Viator-backed pricing.
 */
public enum WaypointPricingStatus {
    /** At least one product price and URL resolved. */
    FOUND,
    /** Partner API responded; no matching attraction/product for this stop. */
    NO_MATCH,
    /** Network/timeout or other transport failure talking to Viator. */
    PARTNER_UNAVAILABLE
}
