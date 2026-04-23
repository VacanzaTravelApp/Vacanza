package com.vacanza.backend.util;

import com.vacanza.backend.dto.internal.PoiResult;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * Collapses Mapbox sub-features of the same landmark into one entry.
 *
 * <p>Mapbox Search Box often returns a landmark's entrances/amenities as separate rows
 * (e.g. "Anıtkabir", "Anıtkabir güvenlik", "Anıtkabir otoparkı"). Their names share a token
 * prefix and their coordinates are within a couple hundred metres, so they represent the
 * same place from a routing standpoint. The plain {@code name.toLowerCase()} dedup misses
 * them and the AI happily schedules two on different days.
 *
 * <p>Two POIs are treated as the same landmark when their tokenized names form a prefix
 * chain (e.g. {@code ["anitkabir"]} vs {@code ["anitkabir","guvenlik"]}) AND their
 * haversine distance is below {@link #NEIGHBOR_METERS}. The entry with the shorter token
 * list wins (typically the parent landmark name).
 */
public final class PoiDedup {

    private static final double NEIGHBOR_METERS = 200.0;
    private static final double EARTH_RADIUS_M = 6_371_000.0;

    private PoiDedup() {}

    /**
     * Returns a new list with near-duplicate sub-features collapsed. Input order is preserved
     * for surviving entries. Safe to call with null/empty input.
     */
    public static List<PoiResult> collapseNearDuplicates(List<PoiResult> input) {
        if (input == null || input.size() < 2) {
            return input == null ? new ArrayList<>() : new ArrayList<>(input);
        }
        List<PoiResult> out = new ArrayList<>();
        List<List<String>> outTokens = new ArrayList<>();
        for (PoiResult p : input) {
            if (p == null || p.getName() == null || p.getName().isBlank()) {
                continue;
            }
            List<String> toks = tokenize(p.getName());
            if (toks.isEmpty()) {
                out.add(p);
                outTokens.add(toks);
                continue;
            }
            int mergeIndex = -1;
            for (int i = 0; i < out.size(); i++) {
                List<String> qToks = outTokens.get(i);
                if (qToks.isEmpty()) continue;
                if (!tokensPrefixRelated(toks, qToks)) continue;
                if (!areNear(p, out.get(i))) continue;
                mergeIndex = i;
                break;
            }
            if (mergeIndex < 0) {
                out.add(p);
                outTokens.add(toks);
                continue;
            }
            // Keep the entry with the shorter token list (the parent landmark).
            if (toks.size() < outTokens.get(mergeIndex).size()) {
                out.set(mergeIndex, p);
                outTokens.set(mergeIndex, toks);
            }
        }
        return out;
    }

    /**
     * True when {@code candidate}'s name tokens are a prefix of — or equal to — any entry in
     * {@code existing} AND the two points are within {@link #NEIGHBOR_METERS}. Used by merge
     * steps that need to decide "is this POI already represented?".
     */
    public static boolean isNearDuplicateOfAny(PoiResult candidate, List<PoiResult> existing) {
        if (candidate == null || candidate.getName() == null || existing == null || existing.isEmpty()) {
            return false;
        }
        List<String> toks = tokenize(candidate.getName());
        if (toks.isEmpty()) return false;
        for (PoiResult q : existing) {
            if (q == null || q.getName() == null) continue;
            List<String> qToks = tokenize(q.getName());
            if (qToks.isEmpty()) continue;
            if (!tokensPrefixRelated(toks, qToks)) continue;
            if (areNear(candidate, q)) return true;
        }
        return false;
    }

    /** True when one token list is a (non-strict) prefix of the other. */
    private static boolean tokensPrefixRelated(List<String> a, List<String> b) {
        List<String> shorter = a.size() <= b.size() ? a : b;
        List<String> longer = a.size() <= b.size() ? b : a;
        for (int i = 0; i < shorter.size(); i++) {
            if (!shorter.get(i).equals(longer.get(i))) return false;
        }
        return true;
    }

    private static boolean areNear(PoiResult a, PoiResult b) {
        return haversineMeters(a.getLat(), a.getLon(), b.getLat(), b.getLon()) <= NEIGHBOR_METERS;
    }

    /**
     * Lowercase, strip diacritics, keep only [a-z0-9 ], drop tokens shorter than 2 chars.
     * Turkish "İ/I/ı/i" and similar diacritic variants normalize to the same form.
     */
    static List<String> tokenize(String name) {
        if (name == null) return List.of();
        String lower = name.toLowerCase(Locale.ROOT).trim();
        String stripped = Normalizer.normalize(lower, Normalizer.Form.NFD)
                .replaceAll("\\p{InCombiningDiacriticalMarks}+", "");
        stripped = stripped.replaceAll("[^a-z0-9 ]", " ").trim();
        if (stripped.isEmpty()) return List.of();
        List<String> toks = new ArrayList<>();
        for (String t : stripped.split("\\s+")) {
            if (t.length() >= 2) toks.add(t);
        }
        return toks;
    }

    private static double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
        double phi1 = Math.toRadians(lat1);
        double phi2 = Math.toRadians(lat2);
        double dPhi = Math.toRadians(lat2 - lat1);
        double dLam = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dPhi / 2) * Math.sin(dPhi / 2)
                + Math.cos(phi1) * Math.cos(phi2) * Math.sin(dLam / 2) * Math.sin(dLam / 2);
        return EARTH_RADIUS_M * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }
}
