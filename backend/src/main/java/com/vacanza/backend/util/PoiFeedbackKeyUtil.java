package com.vacanza.backend.util;

import com.vacanza.backend.dto.internal.PoiCategoryFamily;
import com.vacanza.backend.dto.internal.PoiResult;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;

/**
 * Stable keys for {@link com.vacanza.backend.entity.UserPoiFeedback} and category affinity rows.
 */
public final class PoiFeedbackKeyUtil {

    private PoiFeedbackKeyUtil() {
    }

    public static String foursquareKey(String id) {
        if (id == null || id.isBlank()) {
            return null;
        }
        return "fs:" + id.trim();
    }

    public static String mapboxKey(String id) {
        if (id == null || id.isBlank()) {
            return null;
        }
        return "mb:" + id.trim();
    }

    public static String familyKey(PoiCategoryFamily family) {
        if (family == null) {
            return null;
        }
        return "family:" + family.name();
    }

    public static String normalizeCategoryToken(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        return raw.toLowerCase(Locale.ROOT).trim().replace('-', '_');
    }

    /**
     * Keys to look up POI-level feedback (foursquare preferred when both present in {@link PoiResult}).
     */
    public static List<String> poiLookupKeys(PoiResult p) {
        LinkedHashSet<String> keys = new LinkedHashSet<>();
        if (p.getExternalIds() != null) {
            String fs = p.getExternalIds().get("foursquare");
            String k = foursquareKey(fs);
            if (k != null) {
                keys.add(k);
            }
        }
        if (p.getExternalId() != null && !p.getExternalId().isBlank()) {
            String k = foursquareKey(p.getExternalId().trim());
            if (k != null) {
                keys.add(k);
            }
        }
        String mb = mapboxKey(p.getMapboxId());
        if (mb != null) {
            keys.add(mb);
        }
        return new ArrayList<>(keys);
    }
}
