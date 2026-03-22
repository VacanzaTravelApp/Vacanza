package com.vacanza.backend.service;

import com.vacanza.backend.config.PoiConstraintProperties;
import com.vacanza.backend.dto.internal.PoiResult;
import com.vacanza.backend.dto.internal.PoiRetrievalContext;
import com.vacanza.backend.integration.ai.UserProfileForAi;
import com.vacanza.backend.util.PoiPriceLevelUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.OptionalDouble;
import java.util.OptionalInt;

/**
 * Deterministic filters: closed weekdays (when {@link PoiResult#getClosedWeekdays()} is populated) and
 * budget vs {@link PoiResult#getPriceLevel()} ordinal. When data is missing, behavior is neutral (no-op).
 * <p>
 * Intended order in the pipeline: {@code enrich → score → this → diversify}.
 */
@Component
@RequiredArgsConstructor
public class PoiConstraintFilter {

    private final PoiConstraintProperties props;

    public List<PoiResult> apply(List<PoiResult> pois, UserProfileForAi profile, PoiRetrievalContext ctx) {
        if (pois == null || pois.isEmpty()) {
            return pois == null ? List.of() : pois;
        }
        PoiRetrievalContext safeCtx = ctx != null ? ctx : PoiRetrievalContext.empty();
        List<PoiResult> afterClosed = filterClosedWeekdays(pois, safeCtx);
        return applyBudget(afterClosed, profile);
    }

    private List<PoiResult> filterClosedWeekdays(List<PoiResult> pois, PoiRetrievalContext ctx) {
        if (!props.isClosedDayEnabled()) {
            return new ArrayList<>(pois);
        }
        if (ctx.tripStart() == null || ctx.tripDayIndex() == null || ctx.tripDayIndex() < 1) {
            return new ArrayList<>(pois);
        }
        LocalDate day = ctx.tripStart().plusDays(ctx.tripDayIndex() - 1L);
        DayOfWeek dow = day.getDayOfWeek();
        List<PoiResult> out = new ArrayList<>();
        for (PoiResult p : pois) {
            if (isClosedOnWeekday(p, dow)) {
                continue;
            }
            out.add(p);
        }
        return out;
    }

    /**
     * @return true if POI should be dropped as closed on {@code dow}.
     */
    private boolean isClosedOnWeekday(PoiResult p, DayOfWeek dow) {
        List<String> closed = p.getClosedWeekdays();
        if (closed == null || closed.isEmpty()) {
            return false;
        }
        String name = dow.name();
        for (String c : closed) {
            if (c == null || c.isBlank()) {
                continue;
            }
            if (name.equalsIgnoreCase(c.trim())) {
                return true;
            }
        }
        return false;
    }

    private List<PoiResult> applyBudget(List<PoiResult> pois, UserProfileForAi profile) {
        if (!props.isBudgetEnabled() || profile == null) {
            return new ArrayList<>(pois);
        }
        if (!budgetCurrencyOk(profile)) {
            return new ArrayList<>(pois);
        }
        OptionalInt userMaxTier = resolveUserMaxPriceTier(profile);
        if (userMaxTier.isEmpty()) {
            return new ArrayList<>(pois);
        }
        int maxTier = userMaxTier.getAsInt();
        List<PoiResult> out = new ArrayList<>();
        for (PoiResult p : pois) {
            OptionalInt poiTier = PoiPriceLevelUtil.ordinal(p.getPriceLevel());
            if (poiTier.isEmpty()) {
                out.add(p);
                continue;
            }
            if (poiTier.getAsInt() <= maxTier) {
                out.add(p);
                continue;
            }
            if (props.getBudgetMode() == PoiConstraintProperties.ConstraintMode.DROP) {
                continue;
            }
            double base = p.getRelevanceScore() != null ? p.getRelevanceScore() : 0.0;
            p.setRelevanceScore(base - props.getBudgetPenalty());
            out.add(p);
        }
        if (props.getBudgetMode() == PoiConstraintProperties.ConstraintMode.PENALTY) {
            out.sort(Comparator.comparingDouble((PoiResult x) -> x.getRelevanceScore() != null ? x.getRelevanceScore() : 0.0)
                    .reversed());
        }
        return out;
    }

    private boolean budgetCurrencyOk(UserProfileForAi profile) {
        String expected = props.getExpectedBudgetCurrency();
        if (expected == null || expected.isBlank()) {
            return true;
        }
        String cur = profile.getBudgetCurrency();
        if (cur == null || cur.isBlank()) {
            return true;
        }
        if (!props.isBudgetCurrencyStrict()) {
            return true;
        }
        return expected.equalsIgnoreCase(cur.trim());
    }

    /**
     * Maps daily budget amount to max affordable price tier (1–4). Empty if budget not set or not parseable.
     */
    private OptionalInt resolveUserMaxPriceTier(UserProfileForAi profile) {
        OptionalDouble amount = parseDailyBudgetAmount(profile != null ? profile.getDailyBudget() : null);
        if (amount.isEmpty() || amount.getAsDouble() <= 0) {
            return OptionalInt.empty();
        }
        double a = amount.getAsDouble();
        if (a <= props.getTier1MaxBudget()) {
            return OptionalInt.of(1);
        }
        if (a <= props.getTier2MaxBudget()) {
            return OptionalInt.of(2);
        }
        if (a <= props.getTier3MaxBudget()) {
            return OptionalInt.of(3);
        }
        return OptionalInt.of(4);
    }

    static OptionalDouble parseDailyBudgetAmount(String dailyBudget) {
        if (dailyBudget == null || dailyBudget.isBlank()) {
            return OptionalDouble.empty();
        }
        StringBuilder sb = new StringBuilder();
        boolean seenDot = false;
        for (char c : dailyBudget.trim().toCharArray()) {
            if (Character.isDigit(c)) {
                sb.append(c);
            } else if ((c == '.' || c == ',') && !seenDot) {
                seenDot = true;
                sb.append('.');
            }
        }
        String num = sb.toString();
        if (num.isEmpty() || num.equals(".")) {
            return OptionalDouble.empty();
        }
        try {
            return OptionalDouble.of(Double.parseDouble(num));
        } catch (NumberFormatException e) {
            return OptionalDouble.empty();
        }
    }
}
