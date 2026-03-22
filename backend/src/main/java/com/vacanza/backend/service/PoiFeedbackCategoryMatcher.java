package com.vacanza.backend.service;

import com.vacanza.backend.dto.internal.PoiResult;

import java.util.List;

/**
 * Matches stored category affinity keys (token or family:NAME) against a {@link PoiResult}.
 */
public final class PoiFeedbackCategoryMatcher {

    private PoiFeedbackCategoryMatcher() {
    }

    public static boolean matches(PoiResult poi, String categoryKey) {
        if (poi == null || categoryKey == null || categoryKey.isBlank()) {
            return false;
        }
        String k = categoryKey.trim();
        if (k.regionMatches(true, 0, "family:", 0, 7)) {
            String fam = k.substring(7).trim();
            if (poi.getCategoryFamily() == null) {
                return false;
            }
            return poi.getCategoryFamily().name().equalsIgnoreCase(fam);
        }
        return PoiPreferenceMatcher.matchesAnyToken(poi, List.of(k));
    }
}
