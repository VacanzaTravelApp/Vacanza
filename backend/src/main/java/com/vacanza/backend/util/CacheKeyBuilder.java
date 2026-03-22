package com.vacanza.backend.util;

import com.vacanza.backend.dto.request.AccommodationSearchRequestDTO;
import com.vacanza.backend.dto.request.TransportSearchRequestDTO;

/**
 * Builds deterministic, human-readable cache keys for SerpAPI result caching.
 *
 * <p>Key format examples:
 * <ul>
 *   <li>Flight:  {@code IST_CDG_2025-07-01_null_1_USD}
 *   <li>Hotel:   {@code Paris_2025-07-01_2025-07-05_2_USD_500}
 *   <li>Airport: {@code istanbul}
 * </ul>
 */
public final class CacheKeyBuilder {

    private CacheKeyBuilder() {}

    /**
     * Cache key for a flight search.
     * Captures every parameter that affects SerpAPI results.
     */
    public static String forFlight(TransportSearchRequestDTO req) {
        return String.join("_",
                req.getOrigin().toUpperCase(),
                req.getDestination().toUpperCase(),
                req.getDepartureDate().toString(),
                req.getReturnDate() != null ? req.getReturnDate().toString() : "OW",
                String.valueOf(req.getAdults()),
                req.getCurrency() != null ? req.getCurrency().toUpperCase() : "USD"
        );
    }

    /**
     * Cache key for a hotel search.
     * Budget is included so different budget caps don't share a cache entry.
     */
    public static String forHotel(AccommodationSearchRequestDTO req) {
        return String.join("_",
                sanitize(req.getQuery()),
                req.getCheckInDate().toString(),
                req.getCheckOutDate().toString(),
                String.valueOf(req.getAdults()),
                req.getCurrency() != null ? req.getCurrency().toUpperCase() : "USD",
                req.getBudget() != null ? req.getBudget().toPlainString() : "any"
        );
    }

    /**
     * Cache key for airport autocomplete.
     * Case-insensitive, trimmed query string.
     */
    public static String forAirport(String query) {
        return query.trim().toLowerCase();
    }

    private static String sanitize(String s) {
        if (s == null) return "unknown";
        // Replace spaces and special chars to keep key URL / filesystem safe
        return s.trim().toLowerCase().replaceAll("[^a-z0-9]+", "-");
    }
}
