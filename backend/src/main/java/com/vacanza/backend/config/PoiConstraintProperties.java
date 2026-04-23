package com.vacanza.backend.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * Deterministic POI constraints after enrichment, applied after profile scoring and before diversity.
 * <p>
 * Budget tiers: user's parsed daily budget amount is compared to {@link #tier1MaxBudget} … {@link #tier3MaxBudget}
 * (same currency unit as configured {@link #expectedBudgetCurrency} when set).
 */
@Data
@Component
@ConfigurationProperties(prefix = "vacanza.poi-constraints")
public class PoiConstraintProperties {

    private boolean budgetEnabled = true;

    /**
     * When {@link #budgetCurrencyStrict} and profile {@code budgetCurrency} differ from {@link #expectedBudgetCurrency},
     * budget filtering is skipped (no-op).
     */
    private boolean budgetCurrencyStrict = true;

    /**
     * Expected ISO 4217 code for {@link com.vacanza.backend.integration.ai.UserProfileForAi#getDailyBudget()} amounts.
     * When null, currency check is skipped.
     */
    private String expectedBudgetCurrency = "USD";

    private ConstraintMode budgetMode = ConstraintMode.DROP;

    /** Subtracted from {@link com.vacanza.backend.dto.internal.PoiResult#getRelevanceScore()} when {@link #budgetMode} is PENALTY. */
    private double budgetPenalty = 25.0;

    /**
     * Max daily budget (inclusive) for which the user is considered tier-1-only ($).
     */
    private double tier1MaxBudget = 45.0;

    private double tier2MaxBudget = 95.0;

    private double tier3MaxBudget = 190.0;

    /** When false, closed-day filtering is skipped entirely. */
    private boolean closedDayEnabled = true;

    public enum ConstraintMode {
        DROP,
        PENALTY
    }
}
