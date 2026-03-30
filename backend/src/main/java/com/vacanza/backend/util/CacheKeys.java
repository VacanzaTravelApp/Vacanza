package com.vacanza.backend.util;

import com.vacanza.backend.dto.request.AccommodationSearchRequestDTO;
import com.vacanza.backend.dto.request.TransportSearchRequestDTO;

/**
 * Deterministic cache key builders for SerpAPI results.
 * <p>
 * Rules:
 * <ul>
 *   <li>Null optionals become the literal {@code "any"}</li>
 *   <li>Text inputs are lowercased and special-char-stripped</li>
 *   <li>Fields joined with {@code "_"}</li>
 * </ul>
 */
public final class CacheKeys {

    private CacheKeys() {}

    /**
     * Flight search key.
     * Example: {@code IST_CDG_2025-07-01_OW_1_USD}
     */
    public static String flight(TransportSearchRequestDTO req) {
        return String.join("_",
                req.getOrigin().toUpperCase(),
                req.getDestination().toUpperCase(),
                req.getDepartureDate().toString(),
                req.getReturnDate() != null ? req.getReturnDate().toString() : "OW",
                String.valueOf(req.getAdults()),
                safe(req.getCurrency(), "USD")
        );
    }

    /**
     * Hotel search key.
     * Example: {@code hotels-in-paris_2025-07-01_2025-07-05_2_USD_any}
     */
    public static String hotel(AccommodationSearchRequestDTO req) {
        return String.join("_",
                sanitize(req.getQuery()),
                req.getCheckInDate().toString(),
                req.getCheckOutDate().toString(),
                String.valueOf(req.getAdults()),
                safe(req.getCurrency(), "USD"),
                req.getBudget() != null ? req.getBudget().toPlainString() : "any"
        );
    }

    /**
     * Airport autocomplete key — just the lowercased query.
     * Example: {@code istanbul}
     */
    public static String airport(String query) {
        return query == null ? "" : query.trim().toLowerCase();
    }

    private static String safe(String value, String fallback) {
        return value != null ? value.toUpperCase() : fallback;
    }

    private static String sanitize(String s) {
        if (s == null) return "unknown";
        return s.trim().toLowerCase().replaceAll("[^a-z0-9]+", "-");
    }
}
