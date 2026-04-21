package com.vacanza.backend.util;

import com.vacanza.backend.dto.internal.PoiResult;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PoiDedupTest {

    // Anıtkabir real coordinates; sub-entries are within ~120 m.
    private static PoiResult poi(String name, double lat, double lon) {
        return new PoiResult(name, "monument", lat, lon);
    }

    @Test
    void collapsesAnitkabirSubFeatures() {
        List<PoiResult> in = List.of(
                poi("Anıtkabir", 39.9256, 32.8378),
                poi("Anıtkabir güvenlik", 39.9251, 32.8381),
                poi("Anıtkabir otoparkı", 39.9260, 32.8374));

        List<PoiResult> out = PoiDedup.collapseNearDuplicates(in);

        assertEquals(1, out.size(), "three sub-entries should collapse to one");
        assertEquals("Anıtkabir", out.get(0).getName(), "shortest parent name wins");
    }

    @Test
    void keepsUnrelatedPoisNearby() {
        // Two distinct landmarks inside the same neighborhood should not be collapsed.
        List<PoiResult> in = List.of(
                poi("Topkapı Sarayı", 41.0115, 28.9833),
                poi("Ayasofya", 41.0086, 28.9802));

        List<PoiResult> out = PoiDedup.collapseNearDuplicates(in);

        assertEquals(2, out.size(), "different names must not collapse even if nearby");
    }

    @Test
    void doesNotCollapsePrefixMatchWhenFarApart() {
        // Prefix-related names >200 m apart are NOT the same landmark.
        List<PoiResult> in = List.of(
                poi("Galata", 41.0256, 28.9741),
                poi("Galata Kulesi", 41.0450, 28.9880)); // ~2 km away

        List<PoiResult> out = PoiDedup.collapseNearDuplicates(in);

        assertEquals(2, out.size(), "far-apart prefix match must stay separate");
    }

    @Test
    void collapsesWhenSubEntryAppearsBeforeParent() {
        // Order independence: sub-feature first, parent second.
        List<PoiResult> in = List.of(
                poi("Anıtkabir güvenlik", 39.9251, 32.8381),
                poi("Anıtkabir", 39.9256, 32.8378));

        List<PoiResult> out = PoiDedup.collapseNearDuplicates(in);

        assertEquals(1, out.size());
        assertEquals("Anıtkabir", out.get(0).getName(), "parent should replace earlier sub-entry");
    }

    @Test
    void isNearDuplicateOfAnyRecognizesFavoriteVariant() {
        // A liked POI ("Anıtkabir") should not be appended when the pool already holds a
        // Mapbox sub-feature ("Anıtkabir güvenlik") for the same landmark.
        List<PoiResult> pool = List.of(poi("Anıtkabir güvenlik", 39.9251, 32.8381));
        PoiResult favorite = poi("Anıtkabir", 39.9256, 32.8378);

        assertTrue(PoiDedup.isNearDuplicateOfAny(favorite, pool));
    }

    @Test
    void isNearDuplicateOfAnyLetsDistinctFavoritePass() {
        List<PoiResult> pool = List.of(poi("Topkapı Sarayı", 41.0115, 28.9833));
        PoiResult favorite = poi("Ayasofya", 41.0086, 28.9802);

        assertFalse(PoiDedup.isNearDuplicateOfAny(favorite, pool));
    }
}
