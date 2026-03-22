package com.vacanza.backend.util;

import org.junit.jupiter.api.Test;

import java.util.OptionalInt;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PoiPriceLevelUtilTest {

    @Test
    void dollarSignsMapToOrdinal() {
        assertEquals(OptionalInt.of(1), PoiPriceLevelUtil.ordinal("$"));
        assertEquals(OptionalInt.of(2), PoiPriceLevelUtil.ordinal("$$"));
        assertEquals(OptionalInt.of(4), PoiPriceLevelUtil.ordinal("$$$$"));
    }

    @Test
    void unknownIsEmpty() {
        assertTrue(PoiPriceLevelUtil.ordinal(null).isEmpty());
        assertTrue(PoiPriceLevelUtil.ordinal("").isEmpty());
        assertTrue(PoiPriceLevelUtil.ordinal("moderate").isEmpty());
    }
}
