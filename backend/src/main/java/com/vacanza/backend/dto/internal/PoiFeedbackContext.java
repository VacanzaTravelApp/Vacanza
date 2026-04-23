package com.vacanza.backend.dto.internal;

import java.util.Map;

/**
 * Loaded user feedback for one retrieval request; keys match {@link com.vacanza.backend.service.UserFeedbackService} storage.
 *
 * @param poiScores       keys like {@code fs:abc}, {@code mb:xyz}
 * @param categoryScores  keys: normalized category tokens or {@code family:CULTURE}
 */
public record PoiFeedbackContext(Map<String, Double> poiScores, Map<String, Double> categoryScores) {

    public static PoiFeedbackContext empty() {
        return new PoiFeedbackContext(Map.of(), Map.of());
    }

    public boolean isEmpty() {
        return poiScores.isEmpty() && categoryScores.isEmpty();
    }
}
