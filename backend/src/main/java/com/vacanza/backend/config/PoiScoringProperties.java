package com.vacanza.backend.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Weights for {@link com.vacanza.backend.service.PoiScoreCalculator}.
 * <p>
 * <strong>Avoid policy</strong> ({@link #avoidMode}):
 * <ul>
 *   <li>{@link AvoidMode#DROP} — POI is omitted from the list (score not computed; {@link java.util.OptionalDouble#empty()}).</li>
 *   <li>{@link AvoidMode#PENALTY} — POI stays in the list but {@link #avoidPenalty} is subtracted from the relevance score
 *       (can go negative; callers may sort/filter by score).</li>
 * </ul>
 */
@Data
@Component
@ConfigurationProperties(prefix = "vacanza.poi-scoring")
public class PoiScoringProperties {

    /**
     * Multiplier on normalized rating (0–1 from 0–5 stars).
     */
    private double weightRating = 2.0;

    /**
     * Multiplier on normalized popularity (0–1 from review count).
     */
    private double weightPopularity = 1.0;

    /**
     * Added when POI matches a {@code favoriteCategories} token.
     */
    private double favoriteBonus = 3.0;

    /**
     * Subtracted in {@link AvoidMode#PENALTY} when POI matches {@code avoidCategories}.
     */
    private double avoidPenalty = 50.0;

    /**
     * When {@code rating} is null, use this value (0–1) as the rating component input — no penalty, neutral prior.
     */
    private double neutralRatingPrior = 0.5;

    /**
     * How to apply {@code avoidCategories}.
     */
    private AvoidMode avoidMode = AvoidMode.DROP;

    /**
     * Random ± jitter applied to FOOD-family POI scores after deterministic scoring, so different
     * sessions surface different restaurants. Keep ≤ 0.5 to preserve quality ordering between
     * meaningfully different venues (total deterministic score range is ~0–3). Set to 0 to disable.
     */
    private double diningVarietyJitter = 0.30;

    public enum AvoidMode {
        DROP,
        PENALTY
    }
}
