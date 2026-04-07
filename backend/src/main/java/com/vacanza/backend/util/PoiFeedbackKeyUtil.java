package com.vacanza.backend.util;

import com.vacanza.backend.dto.internal.PoiCategoryFamily;
import com.vacanza.backend.dto.internal.PoiResult;

import java.nio.charset.StandardCharsets;
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
        String wp = waypointIdentityKey(p.getName(), p.getLat(), p.getLon());
        if (wp != null) {
            keys.add(wp);
        }
        return new ArrayList<>(keys);
    }

    /**
     * Stable POI key when Foursquare / Mapbox ids are absent (e.g. AI waypoints: name + coordinates only).
     * Format: {@code wp:}<i>hex</i> where hex is unsigned FNV-1a 64 over UTF-8
     * {@code lower(trim(name))|%.6f(lat)|%.6f(lon)} (US locale).
     */
    public static String waypointIdentityKey(String name, Double lat, Double lon) {
        if (lat == null || lon == null) {
            return null;
        }
        return waypointIdentityKey(name, lat.doubleValue(), lon.doubleValue());
    }

    public static String waypointIdentityKey(String name, double lat, double lon) {
        if (Double.isNaN(lat) || Double.isNaN(lon) || Double.isInfinite(lat) || Double.isInfinite(lon)) {
            return null;
        }
        String n = name == null ? "" : name.trim().toLowerCase(Locale.ROOT);
        String payload = String.format(Locale.US, "%s|%.6f|%.6f", n, lat, lon);
        long h = fnv1a64Utf8(payload);
        return "wp:" + Long.toUnsignedString(h, 16);
    }

    private static long fnv1a64Utf8(String s) {
        long hash = -3750763034362895579L; // 14695981039346656037 (FNV-1a 64 offset)
        long prime = 1099511628211L;
        for (byte b : s.getBytes(StandardCharsets.UTF_8)) {
            hash ^= (b & 0xFFL);
            hash *= prime;
        }
        return hash;
    }
}
