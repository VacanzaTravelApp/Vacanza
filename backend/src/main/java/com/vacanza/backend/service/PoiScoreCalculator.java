package com.vacanza.backend.service;

import com.vacanza.backend.config.PoiScoringProperties;
import com.vacanza.backend.dto.internal.PoiResult;
import com.vacanza.backend.integration.ai.UserProfileForAi;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.OptionalDouble;

/**
 * Turns a POI + optional user profile into a single relevance score for retrieval ordering / filtering.
 * <p>
 * Future: inject user–POI boosts or feedback weights via the same entry point (not implemented yet).
 */
@Component
@RequiredArgsConstructor
public class PoiScoreCalculator {

    private final PoiScoringProperties props;

    /**
     * Relevance score for ordering. Empty if {@link PoiScoringProperties.AvoidMode#DROP} applies and this POI matches
     * {@code avoidCategories}.
     */
    public OptionalDouble score(PoiResult poi, UserProfileForAi profile) {
        if (poi == null) {
            return OptionalDouble.empty();
        }
        if (profile != null
                && PoiPreferenceMatcher.matchesAnyToken(poi, profile.getAvoidCategories())
                && props.getAvoidMode() == PoiScoringProperties.AvoidMode.DROP) {
            return OptionalDouble.empty();
        }

        double s = 0.0;
        s += props.getWeightRating() * ratingComponent(poi);
        s += props.getWeightPopularity() * popularityComponent(poi);

        if (profile != null && PoiPreferenceMatcher.matchesAnyToken(poi, profile.getFavoriteCategories())) {
            s += props.getFavoriteBonus();
        }

        if (profile != null
                && PoiPreferenceMatcher.matchesAnyToken(poi, profile.getAvoidCategories())
                && props.getAvoidMode() == PoiScoringProperties.AvoidMode.PENALTY) {
            s -= props.getAvoidPenalty();
        }

        return OptionalDouble.of(s);
    }

    /** Normalized 0–1; unknown rating uses neutral prior (no penalty). */
    private double ratingComponent(PoiResult poi) {
        if (poi.getRating() != null && poi.getRating() >= 0) {
            return Math.min(1.0, poi.getRating() / 5.0);
        }
        double prior = props.getNeutralRatingPrior();
        if (prior < 0) {
            prior = 0;
        }
        if (prior > 1) {
            prior = 1;
        }
        return prior;
    }

    /** Normalized 0–1 from review count; unknown → 0. */
    private static double popularityComponent(PoiResult poi) {
        if (poi.getReviewCount() == null || poi.getReviewCount() < 0) {
            return 0.0;
        }
        double v = Math.log1p(poi.getReviewCount()) / 12.0;
        return Math.min(1.0, v);
    }
}
