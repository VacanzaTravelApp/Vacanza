package com.vacanza.backend.util;

import com.vacanza.backend.dto.request.AccommodationSearchRequestDTO;
import com.vacanza.backend.dto.request.TransportSearchRequestDTO;

public final class CacheKeys {

    private CacheKeys() {}

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
