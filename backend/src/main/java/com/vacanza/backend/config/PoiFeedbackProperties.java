package com.vacanza.backend.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Weights for {@link com.vacanza.backend.service.PoiScoreCalculator} feedback adjustments and ingest deltas.
 */
@Data
@Component
@ConfigurationProperties(prefix = "vacanza.poi-feedback")
public class PoiFeedbackProperties {

    private boolean enabled = true;

    /** Applied to stored POI affinity when adding to relevance score. */
    private double poiScoreMultiplier = 0.35;

    /** Applied to stored category affinity when adding to relevance score. */
    private double categoryScoreMultiplier = 0.25;

    /**
     * If any matching category affinity is at or below this value, POI is dropped (same as avoid DROP),
     * when {@link #categoryDropEnabled} is true.
     */
    private double categoryDropThreshold = -12.0;

    private boolean categoryDropEnabled = true;

    /** Stored affinity is clamped to [-maxStoredAffinity, +maxStoredAffinity]. */
    private double maxStoredAffinity = 24.0;

    private double deltaThumbsUpPoi = 2.0;
    private double deltaThumbsDownPoi = -2.0;
    private double deltaRemovePoi = -5.0;

    private double deltaThumbsUpCategory = 1.0;
    private double deltaThumbsDownCategory = -1.0;
    private double deltaRemoveCategory = -2.0;
}
