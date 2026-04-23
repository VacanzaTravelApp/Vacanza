package com.vacanza.backend.service;

import com.vacanza.backend.config.PoiFeedbackProperties;
import com.vacanza.backend.config.PoiScoringProperties;
import com.vacanza.backend.dto.internal.PoiFeedbackContext;
import com.vacanza.backend.dto.internal.PoiResult;
import com.vacanza.backend.integration.ai.UserProfileForAi;
import com.vacanza.backend.util.PoiFeedbackKeyUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.OptionalDouble;

/**
 * Turns a POI + optional user profile into a single relevance score for retrieval ordering / filtering.
 * Optional {@link PoiFeedbackContext} applies learned POI/category affinities from {@link UserFeedbackService}.
 */
@Component
@RequiredArgsConstructor
public class PoiScoreCalculator {

    private final PoiScoringProperties props;
    private final PoiFeedbackProperties feedbackProps;

    /**
     * Relevance score for ordering. Empty if {@link PoiScoringProperties.AvoidMode#DROP} applies and this POI matches
     * {@code avoidCategories}, or if feedback category affinity triggers drop.
     */
    public OptionalDouble score(PoiResult poi, UserProfileForAi profile) {
        return score(poi, profile, PoiFeedbackContext.empty());
    }

    public OptionalDouble score(PoiResult poi, UserProfileForAi profile, PoiFeedbackContext feedback) {
        if (poi == null) {
            return OptionalDouble.empty();
        }
        if (profile != null
                && PoiPreferenceMatcher.matchesAnyToken(poi, profile.getAvoidCategories())
                && props.getAvoidMode() == PoiScoringProperties.AvoidMode.DROP) {
            return OptionalDouble.empty();
        }

        PoiFeedbackContext fb = feedback != null ? feedback : PoiFeedbackContext.empty();
        if (feedbackProps.isEnabled() && shouldDropForStrongCategoryDislike(poi, fb)) {
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

        if (feedbackProps.isEnabled() && !fb.isEmpty()) {
            s += poiAffinityAdjustment(poi, fb);
            s += categoryAffinityAdjustment(poi, fb);
        }

        return OptionalDouble.of(s);
    }

    private boolean shouldDropForStrongCategoryDislike(PoiResult poi, PoiFeedbackContext fb) {
        if (!feedbackProps.isCategoryDropEnabled()) {
            return false;
        }
        double thr = feedbackProps.getCategoryDropThreshold();
        for (var e : fb.categoryScores().entrySet()) {
            if (PoiFeedbackCategoryMatcher.matches(poi, e.getKey()) && e.getValue() <= thr) {
                return true;
            }
        }
        return false;
    }

    private double poiAffinityAdjustment(PoiResult poi, PoiFeedbackContext fb) {
        double sum = 0.0;
        for (String k : PoiFeedbackKeyUtil.poiLookupKeys(poi)) {
            Double v = fb.poiScores().get(k);
            if (v != null) {
                sum += v * feedbackProps.getPoiScoreMultiplier();
            }
        }
        return sum;
    }

    private double categoryAffinityAdjustment(PoiResult poi, PoiFeedbackContext fb) {
        double sum = 0.0;
        for (var e : fb.categoryScores().entrySet()) {
            if (PoiFeedbackCategoryMatcher.matches(poi, e.getKey())) {
                sum += e.getValue() * feedbackProps.getCategoryScoreMultiplier();
            }
        }
        return sum;
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
