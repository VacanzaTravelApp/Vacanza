package com.vacanza.backend.service;

import com.vacanza.backend.config.PoiConstraintProperties;
import com.vacanza.backend.dto.internal.PoiResult;
import com.vacanza.backend.dto.internal.PoiRetrievalContext;
import com.vacanza.backend.integration.ai.UserProfileForAi;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PoiConstraintFilterTest {

    @Test
    void budgetDropRemovesOverTier() {
        PoiConstraintProperties p = new PoiConstraintProperties();
        p.setBudgetEnabled(true);
        p.setBudgetMode(PoiConstraintProperties.ConstraintMode.DROP);
        p.setBudgetCurrencyStrict(false);
        p.setTier1MaxBudget(40);
        p.setTier2MaxBudget(80);
        p.setTier3MaxBudget(150);
        PoiConstraintFilter f = new PoiConstraintFilter(p);

        UserProfileForAi profile = UserProfileForAi.builder().dailyBudget("50").build();
        PoiResult cheap = poi("A", "$", 10.0);
        PoiResult expensive = poi("B", "$$$", 10.0);
        List<PoiResult> out = f.apply(List.of(cheap, expensive), profile, PoiRetrievalContext.empty());
        assertEquals(1, out.size());
        assertEquals("A", out.get(0).getName());
    }

    @Test
    void unknownPriceLevelStaysNeutral() {
        PoiConstraintProperties p = new PoiConstraintProperties();
        p.setBudgetEnabled(true);
        p.setBudgetMode(PoiConstraintProperties.ConstraintMode.DROP);
        p.setBudgetCurrencyStrict(false);
        p.setTier1MaxBudget(10);
        PoiConstraintFilter f = new PoiConstraintFilter(p);

        UserProfileForAi profile = UserProfileForAi.builder().dailyBudget("5").build();
        PoiResult unknown = poi("U", null, 10.0);
        List<PoiResult> out = f.apply(List.of(unknown), profile, PoiRetrievalContext.empty());
        assertEquals(1, out.size());
    }

    @Test
    void closedWeekdayDropsWhenTripContextAndDataPresent() {
        PoiConstraintProperties p = new PoiConstraintProperties();
        p.setBudgetEnabled(false);
        p.setClosedDayEnabled(true);
        PoiConstraintFilter f = new PoiConstraintFilter(p);

        PoiResult closedMon = poi("M", "$", 10.0);
        closedMon.setClosedWeekdays(List.of("MONDAY"));
        PoiResult open = poi("O", "$", 10.0);
        PoiRetrievalContext ctx = new PoiRetrievalContext(LocalDate.of(2025, 3, 17), 1, 3);
        List<PoiResult> out = f.apply(List.of(closedMon, open), null, ctx);
        assertEquals(1, out.size());
        assertEquals("O", out.get(0).getName());
    }

    @Test
    void parseDailyBudgetStripsSymbols() {
        assertTrue(PoiConstraintFilter.parseDailyBudgetAmount("€ 120,50").isPresent());
        assertEquals(120.5, PoiConstraintFilter.parseDailyBudgetAmount("€ 120,50").getAsDouble(), 1e-9);
    }

    private static PoiResult poi(String name, String price, double score) {
        PoiResult r = new PoiResult(name, "museum", 0, 0);
        r.setPriceLevel(price);
        r.setRelevanceScore(score);
        return r;
    }
}
