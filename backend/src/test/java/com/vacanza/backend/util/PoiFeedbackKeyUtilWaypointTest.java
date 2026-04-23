package com.vacanza.backend.util;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;

class PoiFeedbackKeyUtilWaypointTest {

    @Test
    void waypointIdentityKey_stableForSameInputs() {
        String a = PoiFeedbackKeyUtil.waypointIdentityKey("Ayasofya", 41.0086, 28.9802);
        String b = PoiFeedbackKeyUtil.waypointIdentityKey("Ayasofya", 41.0086, 28.9802);
        assertEquals(a, b);
        assertEquals("wp:", a.substring(0, 3));
        // Must stay in sync with web `waypointIdentityPoiKey` (FNV-1a 64 + UTF-8 payload).
        assertEquals("wp:72a2fb86addfedd2", a);
    }

    @Test
    void waypointIdentityKey_nullWithoutCoords() {
        assertNull(PoiFeedbackKeyUtil.waypointIdentityKey("X", null, 1.0));
        assertNull(PoiFeedbackKeyUtil.waypointIdentityKey("X", 1.0, null));
    }
}
