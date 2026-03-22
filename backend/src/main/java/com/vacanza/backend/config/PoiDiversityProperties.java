package com.vacanza.backend.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * POI list diversification after scoring ({@link com.vacanza.backend.service.PoiDiversitySelector}).
 */
@Data
@Component
@ConfigurationProperties(prefix = "vacanza.poi-diversity")
public class PoiDiversityProperties {

    private boolean enabled = true;

    /** Max POIs passed to the LLM tool payload (after diversity). */
    private int targetCount = 60;

    /**
     * Only the top {@code poolSize} by relevance participate in diversification (rest discarded for this request).
     */
    private int poolSize = 120;

    private DiversityMode mode = DiversityMode.MMR;

    /**
     * MMR trade-off: higher = more relevance, lower = more variety. Typical 0.5–0.85.
     */
    private double mmrLambda = 0.72;

    /**
     * In {@link DiversityMode#FAMILY_CAP}: max POIs per {@link com.vacanza.backend.dto.internal.PoiCategoryFamily} in the output.
     */
    private int maxPerFamily = 4;

    public enum DiversityMode {
        MMR,
        FAMILY_CAP
    }
}
