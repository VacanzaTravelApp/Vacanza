package com.vacanza.backend.util;

import java.util.OptionalInt;

/**
 * Maps POI {@code priceLevel} strings (e.g. {@code $}, {@code $$$$}) to ordinals 1–4.
 * Unknown or missing values are neutral (empty).
 */
public final class PoiPriceLevelUtil {

    private PoiPriceLevelUtil() {
    }

    /**
     * @return 1–4 for inexpensive–expensive; empty if unknown (neutral for filtering).
     */
    public static OptionalInt ordinal(String priceLevel) {
        if (priceLevel == null || priceLevel.isBlank()) {
            return OptionalInt.empty();
        }
        String s = priceLevel.trim();
        int dollars = 0;
        for (int i = 0; i < s.length(); i++) {
            if (s.charAt(i) == '$') {
                dollars++;
            }
        }
        if (dollars >= 1 && dollars <= 4) {
            return OptionalInt.of(dollars);
        }
        if (s.length() == 1 && Character.isDigit(s.charAt(0))) {
            int d = s.charAt(0) - '0';
            if (d >= 1 && d <= 4) {
                return OptionalInt.of(d);
            }
        }
        return OptionalInt.empty();
    }
}
