package com.vacanza.backend.service;

import com.vacanza.backend.config.PoiScoringProperties;
import com.vacanza.backend.dto.internal.PoiResult;
import com.vacanza.backend.integration.ai.UserProfileForAi;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.OptionalDouble;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PoiScoreCalculatorTest {

    @Test
    void drop_mode_excludes_avoided_category() {
        PoiScoringProperties p = new PoiScoringProperties();
        p.setAvoidMode(PoiScoringProperties.AvoidMode.DROP);
        PoiScoreCalculator calc = new PoiScoreCalculator(p);

        PoiResult museum = new PoiResult("X", "museum", 41.0, 29.0);
        UserProfileForAi profile = UserProfileForAi.builder()
                .avoidCategories(List.of("museum"))
                .build();

        assertTrue(calc.score(museum, profile).isEmpty());
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
        PoiScoreCalculator calc = new PoiScoreCalculator(p);

        PoiResult museum = new PoiResult("X", "museum", 41.0, 29.0);
        UserProfileForAi profile = UserProfileForAi.builder()
                .avoidCategories(List.of("museum"))
                .build();

        OptionalDouble s = calc.score(museum, profile);
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
        PoiScoreCalculator calc = new PoiScoreCalculator(p);

        PoiResult prk = new PoiResult("Park", "park", 41.0, 29.0);
        UserProfileForAi profile = UserProfileForAi.builder()
                .favoriteCategories(List.of("park"))
                .build();

        assertEquals(5.0, calc.score(prk, profile).getAsDouble(), 1e-9);
    }

    @Test
    void null_profile_uses_neutral_rating_prior_only() {
        PoiScoringProperties p = new PoiScoringProperties();
        p.setWeightRating(2.0);
        p.setWeightPopularity(0.0);
        p.setNeutralRatingPrior(0.5);
        PoiScoreCalculator calc = new PoiScoreCalculator(p);

        PoiResult poi = new PoiResult("A", "landmark", 41.0, 29.0);
        assertEquals(1.0, calc.score(poi, null).getAsDouble(), 1e-9);
    }
}
