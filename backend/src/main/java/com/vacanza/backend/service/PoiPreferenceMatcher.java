package com.vacanza.backend.service;

import com.vacanza.backend.dto.internal.PoiResult;

import java.util.List;
import java.util.Locale;

/**
 * Matches user preference tokens (favorite / avoid) against POI category, Mapbox ids, and {@link com.vacanza.backend.dto.internal.PoiCategoryFamily}.
 */
public final class PoiPreferenceMatcher {

    private PoiPreferenceMatcher() {
    }

    public static boolean matchesAnyToken(PoiResult poi, List<String> preferenceTokens) {
        if (preferenceTokens == null || preferenceTokens.isEmpty() || poi == null) {
            return false;
        }
        for (String raw : preferenceTokens) {
            if (raw == null || raw.isBlank()) {
                continue;
            }
            String token = normalize(raw);
            if (token.length() < 2) {
                continue;
            }
            if (matches(poi, token)) {
                return true;
            }
        }
        return false;
    }

    private static String normalize(String s) {
        return s.toLowerCase(Locale.ROOT).trim().replace('-', '_');
    }

    private static boolean matches(PoiResult poi, String token) {
        if (fieldMatches(poi.getCategory(), token)) {
            return true;
        }
        if (poi.getPoiCategoryIds() != null) {
            for (String id : poi.getPoiCategoryIds()) {
                if (fieldMatches(id, token)) {
                    return true;
                }
            }
        }
        if (poi.getCategoryFamily() != null) {
            String fam = poi.getCategoryFamily().name().toLowerCase(Locale.ROOT);
            if (fam.equals(token) || (token.length() >= 3 && fam.contains(token))) {
                return true;
            }
        }
        return false;
    }

    private static boolean fieldMatches(String haystack, String token) {
        if (haystack == null || haystack.isBlank()) {
            return false;
        }
        String h = haystack.toLowerCase(Locale.ROOT).replace('-', '_');
        return h.equals(token) || (token.length() >= 3 && h.contains(token));
    }
}
