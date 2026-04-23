package com.vacanza.backend.service;

import com.vacanza.backend.config.PoiFeedbackProperties;
import com.vacanza.backend.config.PoiScoringProperties;
import com.vacanza.backend.dto.internal.PoiFeedbackContext;
import com.vacanza.backend.dto.internal.PoiResult;
import com.vacanza.backend.integration.ai.UserProfileForAi;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;
import java.util.OptionalDouble;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PoiScoreCalculatorTest {

    private static PoiScoreCalculator calc(PoiScoringProperties p) {
        PoiFeedbackProperties fp = new PoiFeedbackProperties();
        fp.setEnabled(false);
        return new PoiScoreCalculator(p, fp);
    }

    @Test
    void drop_mode_excludes_avoided_category() {
        PoiScoringProperties p = new PoiScoringProperties();
        p.setAvoidMode(PoiScoringProperties.AvoidMode.DROP);
        PoiScoreCalculator calculator = calc(p);

        PoiResult museum = new PoiResult("X", "museum", 41.0, 29.0);
        UserProfileForAi profile = UserProfileForAi.builder()
                .avoidCategories(List.of("museum"))
                .build();

        assertTrue(calculator.score(museum, profile).isEmpty());
    }

    @Test
    void penalty_mode_keeps_but_lowers_score() {
        PoiScoringProperties p = new PoiScoringProperties();
        p.setAvoidMode(PoiScoringProperties.AvoidMode.PENALTY);
        p.setAvoidPenalty(40.0);
        p.setWeightRating(0.0);
        p.setWeightPopularity(0.0);
        p.setFavoriteBonus(0.0);
        p.setNeutralRatingPrior(0.0);
        PoiScoreCalculator calculator = calc(p);

        PoiResult museum = new PoiResult("X", "museum", 41.0, 29.0);
        UserProfileForAi profile = UserProfileForAi.builder()
                .avoidCategories(List.of("museum"))
                .build();

        OptionalDouble s = calculator.score(museum, profile);
        assertTrue(s.isPresent());
        assertEquals(-40.0, s.getAsDouble(), 1e-9);
    }

    @Test
    void favorite_adds_bonus() {
        PoiScoringProperties p = new PoiScoringProperties();
        p.setWeightRating(0.0);
        p.setWeightPopularity(0.0);
        p.setFavoriteBonus(5.0);
        p.setNeutralRatingPrior(0.0);
        PoiScoreCalculator calculator = calc(p);

        PoiResult prk = new PoiResult("Park", "park", 41.0, 29.0);
        UserProfileForAi profile = UserProfileForAi.builder()
                .favoriteCategories(List.of("park"))
                .build();

        assertEquals(5.0, calculator.score(prk, profile).getAsDouble(), 1e-9);
    }

    @Test
    void null_profile_uses_neutral_rating_prior_only() {
        PoiScoringProperties p = new PoiScoringProperties();
        p.setWeightRating(2.0);
        p.setWeightPopularity(0.0);
        p.setNeutralRatingPrior(0.5);
        PoiScoreCalculator calculator = calc(p);

        PoiResult poi = new PoiResult("A", "landmark", 41.0, 29.0);
        assertEquals(1.0, calculator.score(poi, null).getAsDouble(), 1e-9);
    }

    @Test
    void poi_feedback_boosts_score() {
        PoiScoringProperties p = new PoiScoringProperties();
        p.setWeightRating(0.0);
        p.setWeightPopularity(0.0);
        p.setNeutralRatingPrior(0.0);
        PoiFeedbackProperties fp = new PoiFeedbackProperties();
        fp.setEnabled(true);
        fp.setPoiScoreMultiplier(1.0);
        PoiScoreCalculator calculator = new PoiScoreCalculator(p, fp);

        PoiResult poi = new PoiResult("X", "museum", 0, 0);
        poi.setMapboxId("mid");
        PoiFeedbackContext fb = new PoiFeedbackContext(Map.of("mb:mid", 4.0), Map.of());
        assertEquals(4.0, calculator.score(poi, null, fb).getAsDouble(), 1e-9);
    }

    @Test
    void strong_category_dislike_drops() {
        PoiScoringProperties p = new PoiScoringProperties();
        p.setWeightRating(0.0);
        p.setWeightPopularity(0.0);
        p.setNeutralRatingPrior(1.0);
        PoiFeedbackProperties fp = new PoiFeedbackProperties();
        fp.setEnabled(true);
        fp.setCategoryDropEnabled(true);
        fp.setCategoryDropThreshold(-10.0);
        PoiScoreCalculator calculator = new PoiScoreCalculator(p, fp);

        PoiResult poi = new PoiResult("X", "museum", 0, 0);
        PoiFeedbackContext fb = new PoiFeedbackContext(Map.of(), Map.of("museum", -15.0));
        assertTrue(calculator.score(poi, null, fb).isEmpty());
    }
}
