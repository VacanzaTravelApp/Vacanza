package com.vacanza.backend.integration;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.vacanza.backend.dto.internal.PoiResult;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.text.Normalizer;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Mapbox Search Box API client for agentic POI search:
 * - destination geocode (forward) -> bbox
 * - category search within bbox
 * <p>
 * Category response shape: GeoJSON FeatureCollection; see
 * {@code docs/mapbox-search-box-category-response.md} and official Search Box docs.
 * Rating / review counts are not part of the standard category response; those may come from DB enrichment.
 */
@Slf4j
@Component
public class MapboxPoiSearchClient {

    private final WebClient webClient;

    // Mapbox canonical category IDs used by Search Box category search.
    private static final Map<String, String> CATEGORY_MAP = Map.ofEntries(
            Map.entry("museum", "museum"),
            Map.entry("monument", "monument"),
            Map.entry("memorial", "monument"),
            Map.entry("historic_site", "historic_site"),
            Map.entry("church", "place_of_worship"),
            Map.entry("mosque", "place_of_worship"),
            Map.entry("palace", "historic_site"),
            Map.entry("landmark", "landmark"),
            Map.entry("attraction", "tourist_attraction"),
            Map.entry("tourist_attraction", "tourist_attraction"),
            Map.entry("park", "park"),
            Map.entry("art_gallery", "art_gallery"),
            Map.entry("restaurant", "restaurant"),
            Map.entry("fast_food", "fast_food"),
            Map.entry("market", "market"),
            Map.entry("shopping", "shopping_mall"),
            Map.entry("shopping_mall", "shopping_mall"),
            Map.entry("bazaar", "market"),
            Map.entry("cafe", "cafe"),
            Map.entry("bar", "bar"),
            Map.entry("nightlife", "nightclub"),
            Map.entry("nightclub", "nightclub"),
            Map.entry("pub", "bar"),
            Map.entry("food", "restaurant"),
            Map.entry("bakery", "bakery"),
            Map.entry("neighborhood", "tourist_attraction"),
            Map.entry("ruins", "historic_site"),
            Map.entry("castle", "historic_site"),
            Map.entry("beach", "beach"),
            Map.entry("viewpoint", "tourist_attraction"),
            Map.entry("zoo", "zoo"),
            Map.entry("aquarium", "aquarium"),
            Map.entry("garden", "park"),
            Map.entry("winery", "winery"),
            Map.entry("amusement_park", "amusement_park"),
            Map.entry("theme_park", "amusement_park"),
            Map.entry("observation_deck", "tourist_attraction"),
            Map.entry("scenic_lookout", "tourist_attraction"),
            Map.entry("bridge", "landmark"),
            Map.entry("tower", "landmark"),
            Map.entry("stadium", "stadium"),
            Map.entry("amphitheater", "historic_site"),
            Map.entry("national_park", "park")
    );

    public MapboxPoiSearchClient(@Qualifier("mapboxGeocodingWebClient") WebClient webClient) {
        this.webClient = webClient;
    }

    /**
     * Geocode destination via /forward and return bbox + center.
     */
    public Mono<DestinationGeocodeResult> geocodeDestination(String destination) {
        return webClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/search/searchbox/v1/forward")
                        .queryParam("q", destination)
                        .queryParam("limit", 5)
                        .queryParam("types", "place,locality,neighborhood,region,country")
                        .queryParam("language", "en")
                        .build())
                .retrieve()
                .bodyToMono(FeatureCollection.class)
                .flatMap(resp -> {
                    if (resp == null || resp.getFeatures() == null || resp.getFeatures().isEmpty()) {
                        return Mono.empty();
                    }
                    for (Feature f : resp.getFeatures()) {
                        if (f == null || f.getProperties() == null) continue;
                        Coordinates c = f.getProperties().getCoordinates();
                        if (c == null || c.getLatitude() == null || c.getLongitude() == null) continue;

                        List<Double> bbox = f.getProperties().getBbox();
                        if (bbox != null && bbox.size() == 4) {
                            return Mono.just(new DestinationGeocodeResult(
                                    c.getLatitude(), c.getLongitude(),
                                    bbox.get(0), bbox.get(1), bbox.get(2), bbox.get(3)
                            ));
                        }

                        double lat = c.getLatitude();
                        double lon = c.getLongitude();
                        double dLat = 0.18d;
                        double dLon = 0.22d;
                        return Mono.just(new DestinationGeocodeResult(
                                lat, lon,
                                lon - dLon, lat - dLat, lon + dLon, lat + dLat
                        ));
                    }
                    return Mono.empty();
                })
                .onErrorResume(e -> Mono.empty());
    }

    /**
     * Category search within bbox.
     */
    public Mono<List<PoiResult>> searchByCategory(String category,
            double minLon, double minLat,
            double maxLon, double maxLat) {
        String normalized = category == null ? "" : category.toLowerCase(Locale.ROOT).trim();
        String mapboxCategory = CATEGORY_MAP.getOrDefault(normalized, normalized);

        log.info("[POI SEARCH] category={} bbox={},{},{},{}",
                mapboxCategory, minLon, minLat, maxLon, maxLat);

        return webClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/search/searchbox/v1/category/{category}")
                        .queryParam("bbox", minLon + "," + minLat + "," + maxLon + "," + maxLat)
                        .queryParam("limit", 20)
                        .queryParam("language", "en")
                        .build(mapboxCategory))
                .retrieve()
                .bodyToMono(FeatureCollection.class)
                .map(resp -> {
                    if (resp == null || resp.getFeatures() == null) return List.<PoiResult>of();
                    return resp.getFeatures().stream()
                            .map(f -> toPoiResult(f, normalized))
                            .filter(x -> x != null)
                            .toList();
                })
                .onErrorResume(e -> Mono.just(List.of()));
    }

    /**
     * Forward (text) search for a specific place name within a bbox.
     * Used to resolve must_visit landmarks that category search may miss.
     *
     * types=poi,place: "place" type catches named physical features (bridges, hills,
     * viewpoints) that Mapbox may not index purely as "poi" in the Search Box API.
     */
    public Mono<List<PoiResult>> forwardSearchPoi(String query,
            double minLon, double minLat,
            double maxLon, double maxLat) {
        log.info("[POI FORWARD] query='{}' bbox={},{},{},{}", query, minLon, minLat, maxLon, maxLat);
        return webClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/search/searchbox/v1/forward")
                        .queryParam("q", query)
                        .queryParam("limit", 3)
                        .queryParam("types", "poi,place")
                        .queryParam("bbox", minLon + "," + minLat + "," + maxLon + "," + maxLat)
                        .queryParam("language", "en")
                        .build())
                .retrieve()
                .bodyToMono(FeatureCollection.class)
                .map(resp -> {
                    if (resp == null || resp.getFeatures() == null) return List.<PoiResult>of();
                    return resp.getFeatures().stream()
                            .map(f -> toPoiResult(f, "attraction"))
                            .filter(x -> x != null)
                            .toList();
                })
                .onErrorResume(e -> {
                    log.warn("[POI FORWARD] failed for '{}': {}", query, e.getMessage());
                    return Mono.just(List.of());
                });
    }


    /**
     * High-level resolver: tries suggest+retrieve → forward search → geocoding v5.
     * suggest+retrieve is tried first because it uses proximity-biased ranking, which
     * prevents Mapbox's duplicate/stale index entries (wrong coordinates for the same
     * place name) from winning — forward search on a wide city bbox can return the
     * wrong entry first (e.g. a mall vs. the actual Grand Bazaar 5 km away).
     */
    public Mono<PoiResult> resolvePlace(String placeName, String destination,
            double minLon, double minLat, double maxLon, double maxLat) {
        String query = placeName.contains(",") ? placeName : placeName + ", " + destination;
        // ASCII-normalized fallback query: NFD decomposition strips combining diacritical marks
        // universally (works for any language: Turkish, French, German, Arabic romanization, etc.)
        // Any characters that still don't decompose to ASCII are dropped entirely.
        // "Göbeklitepe, Şanlıurfa" → "Gobeklitepe, Sanliurfa"
        // "Château de Versailles" → "Chateau de Versailles"
        String queryAscii = Normalizer.normalize(query, Normalizer.Form.NFD)
                .replaceAll("\\p{InCombiningDiacriticalMarks}+", "")
                .replaceAll("[^\\x00-\\x7F]", "");
        boolean hasNonAscii = !queryAscii.equals(query);

        double proxLon = (minLon + maxLon) / 2;
        double proxLat = (minLat + maxLat) / 2;

        // Step 1: suggest+retrieve — proximity-biased ranking keeps the canonical landmark
        // first (beats stale/duplicate Mapbox entries far from city center).
        // No bbox passed to suggest: Mapbox's suggest API changes result ranking when bbox is
        // applied and can surface wrong entries. Name-based selection handles disambiguation.
        return suggestAndRetrieve(query, placeName, proxLon, proxLat)
                .doOnNext(r -> log.info("[RESOLVE] Step 1 (suggest+retrieve) hit for '{}'", placeName))

                // Step 2: forward search in bbox
                .switchIfEmpty(Mono.defer(() -> {
                    log.info("[RESOLVE] Step 2 (forward/bbox) for '{}'", placeName);
                    return forwardSearchPoi(query, minLon, minLat, maxLon, maxLat)
                            .flatMap(results -> results.isEmpty() ? Mono.<PoiResult>empty() : Mono.just(results.get(0)));
                }))

                // Step 3: forward search with expanded bbox (+50%)
                .switchIfEmpty(Mono.defer(() -> {
                    double latRange = (maxLat - minLat) * 0.5;
                    double lonRange = (maxLon - minLon) * 0.5;
                    log.info("[RESOLVE] Step 3 (forward/expanded-bbox) for '{}'", placeName);
                    return forwardSearchPoi(query,
                            minLon - lonRange, minLat - latRange,
                            maxLon + lonRange, maxLat + latRange)
                            .flatMap(r -> r.isEmpty() ? Mono.<PoiResult>empty() : Mono.just(r.get(0)));
                }))

                // Step 4: forward search without bbox (global, proximity-biased)
                .switchIfEmpty(Mono.defer(() -> {
                    log.info("[RESOLVE] Step 4 (forward/no-bbox) for '{}'", placeName);
                    return forwardSearchPoiWithProximity(query, proxLon, proxLat);
                }))

                // Step 5: Geocoding API v5 — broader coverage for bridges, hills, viewpoints,
                // natural features and infrastructure that Search Box (Steps 1-4) may miss.
                .switchIfEmpty(Mono.defer(() -> {
                    log.info("[RESOLVE] Step 5 (geocoding-v5/bbox) for '{}'", placeName);
                    return geocodingV5Forward(query, minLon, minLat, maxLon, maxLat);
                }))

                // Step 6: Geocoding v5 without bbox — last-resort for very prominent landmarks
                .switchIfEmpty(Mono.defer(() -> {
                    log.info("[RESOLVE] Step 6 (geocoding-v5/no-bbox) for '{}'", placeName);
                    return geocodingV5Forward(query, -180, -90, 180, 90);
                }))

                // Step 7: ASCII-normalized query — handles Turkish/accented place names
                // whose diacritics cause Mapbox index misses (e.g. "Göbeklitepe" → "Gobeklitepe").
                // Only attempted when the original query contains non-ASCII characters.
                .switchIfEmpty(Mono.defer(() -> {
                    if (!hasNonAscii) return Mono.empty();
                    log.info("[RESOLVE] Step 7 (ascii-normalized) for '{}'", placeName);
                    return geocodingV5Forward(queryAscii, minLon, minLat, maxLon, maxLat)
                            .switchIfEmpty(geocodingV5Forward(queryAscii, -180, -90, 180, 90));
                }))

                .doOnNext(r -> log.info("[RESOLVE] '{}' -> ({}, {})", placeName, r.getLat(), r.getLon()));
    }

    /**
     * Forward search without bbox, using proximity bias only (global scope).
     * Last-resort fallback — wider net but proximity keeps results relevant.
     */
    public Mono<PoiResult> forwardSearchPoiWithProximity(String query, double proxLon, double proxLat) {
        return webClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/search/searchbox/v1/forward")
                        .queryParam("q", query)
                        .queryParam("limit", 3)
                        .queryParam("types", "poi,address")
                        .queryParam("proximity", proxLon + "," + proxLat)
                        .queryParam("language", "en")
                        .build())
                .retrieve()
                .bodyToMono(FeatureCollection.class)
                .flatMap(resp -> {
                    if (resp == null || resp.getFeatures() == null || resp.getFeatures().isEmpty()) {
                        return Mono.empty();
                    }
                    PoiResult r = toPoiResult(resp.getFeatures().get(0), "attraction");
                    return r != null ? Mono.just(r) : Mono.empty();
                })
                .onErrorResume(e -> {
                    log.warn("[POI FORWARD/PROXIMITY] failed for '{}': {}", query, e.getMessage());
                    return Mono.empty();
                });
    }

    /**
     * Suggest + Retrieve 2-step flow for fuzzy POI matching.
     * Uses proximity bias only (no bbox) — call suggestAndRetrieveWithBbox for constrained search.
     */
    public Mono<PoiResult> suggestAndRetrieve(String query, String placeName, double proxLon, double proxLat) {
        return suggestAndRetrieveWithBbox(query, placeName, proxLon, proxLat, null);
    }

    /**
     * Suggest + Retrieve with an optional bbox constraint.
     * Combines proximity-biased ranking with name-based selection to avoid accepting
     * unrelated POIs that happen to share words with the query (e.g. "London Eye Bar"
     * when searching for "London Eye").
     * Pass null for bbox to search globally with proximity bias only.
     */
    public Mono<PoiResult> suggestAndRetrieveWithBbox(String query, String placeName, double proxLon, double proxLat, double[] bbox) {
        String sessionToken = java.util.UUID.randomUUID().toString();
        // Core name to match against: strip the ", Destination" suffix if present.
        String coreName = placeName.contains(",")
                ? placeName.substring(0, placeName.indexOf(',')).trim()
                : placeName.trim();
        return webClient.get()
                .uri(uriBuilder -> {
                    var b = uriBuilder
                            .path("/search/searchbox/v1/suggest")
                            .queryParam("q", query)
                            .queryParam("limit", 5)
                            .queryParam("types", "poi")
                            .queryParam("proximity", proxLon + "," + proxLat)
                            .queryParam("language", "en")
                            .queryParam("session_token", sessionToken);
                    if (bbox != null && bbox.length == 4) {
                        b = b.queryParam("bbox", bbox[0] + "," + bbox[1] + "," + bbox[2] + "," + bbox[3]);
                    }
                    return b.build();
                })
                .retrieve()
                .bodyToMono(SuggestResponse.class)
                .flatMap(resp -> {
                    if (resp == null || resp.getSuggestions() == null || resp.getSuggestions().isEmpty()) {
                        return Mono.empty();
                    }
                    // Pick the best-matching POI suggestion by name similarity.
                    // Prefer an exact/contained name match over the raw Mapbox rank, so a
                    // high-ranked "London Eye Bar" does not win over "The London Eye".
                    Suggestion best = null;
                    int bestScore = -1;
                    for (Suggestion s : resp.getSuggestions()) {
                        if (s == null || s.getMapboxId() == null || s.getMapboxId().isBlank()) continue;
                        if (!"poi".equals(s.getFeatureType())) continue;
                        int score = suggestionNameScore(coreName, s.getName());
                        if (score > bestScore) {
                            bestScore = score;
                            best = s;
                        }
                    }
                    // Only accept if the name is at least loosely related; otherwise fall through
                    // to subsequent steps that can do bbox-constrained forward search.
                    if (best == null || bestScore < 0) return Mono.empty();
                    String mapboxId = best.getMapboxId();
                    log.info("[SUGGEST] best match for '{}': name='{}' score={} id={}",
                            coreName, best.getName(), bestScore, mapboxId);
                    return retrieveByMapboxId(mapboxId, sessionToken);
                })
                .onErrorResume(e -> {
                    log.warn("[SUGGEST+RETRIEVE] failed for '{}': {}", query, e.getMessage());
                    return Mono.empty();
                });
    }

    /**
     * Name similarity score between the searched place name and a suggestion's name.
     * Higher is better; negative means no meaningful overlap (suggestion rejected).
     *   2 — exact match or full containment (e.g. "London Eye" ⊂ "The London Eye")
     *   1 — all significant words (>3 chars) of the place name appear in suggestion
     *   0 — at least one significant word matches
     *  -1 — no overlap (suggestion should be skipped)
     */
    private static int suggestionNameScore(String placeName, String suggestionName) {
        if (placeName == null || suggestionName == null) return -1;
        String pn = placeName.toLowerCase(Locale.ROOT).trim();
        String sn = suggestionName.toLowerCase(Locale.ROOT).trim();
        // Full containment
        if (sn.contains(pn) || pn.contains(sn)) return 2;
        // Word-level overlap
        String[] pWords = pn.split("[\\s,\\-/.']+");
        String[] sWords = sn.split("[\\s,\\-/.']+");
        java.util.List<String> sigWords = new java.util.ArrayList<>();
        for (String w : pWords) { if (w.length() > 3) sigWords.add(w); }
        if (sigWords.isEmpty()) return sn.contains(pn) ? 1 : -1;
        int matched = 0;
        for (String pw : sigWords) {
            for (String sw : sWords) {
                if (sw.equals(pw)) { matched++; break; }
            }
        }
        if (matched == sigWords.size()) return 1;
        if (matched > 0) return 0;
        return -1;
    }

    /**
     * Retrieve feature details (coordinates) by mapbox_id.
     * Used after /suggest to get exact coordinates.
     */
    private Mono<PoiResult> retrieveByMapboxId(String mapboxId, String sessionToken) {
        return webClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/search/searchbox/v1/retrieve/{id}")
                        .queryParam("session_token", sessionToken)
                        .build(mapboxId))
                .retrieve()
                .bodyToMono(FeatureCollection.class)
                .flatMap(resp -> {
                    if (resp == null || resp.getFeatures() == null || resp.getFeatures().isEmpty()) {
                        return Mono.empty();
                    }
                    PoiResult r = toPoiResult(resp.getFeatures().get(0), "attraction");
                    return r != null ? Mono.just(r) : Mono.empty();
                })
                .onErrorResume(e -> {
                    log.warn("[RETRIEVE] failed for mapboxId='{}': {}", mapboxId, e.getMessage());
                    return Mono.empty();
                });
    }

    /**
     * Mapbox Geocoding API v5 forward search.
     *
     * <p>The Search Box API (/search/searchbox) is optimised for businesses and POIs with Foursquare
     * data. It often misses infrastructure (bridges, tunnels) and natural features (hills, bays,
     * viewpoints) that are indexed under the legacy Geocoding v5 dataset.
     *
     * <p>Used as Steps 5/6 in {@link #resolvePlace} after all Search Box strategies fail.
     * bbox="-180,-90,180,90" disables the bounding-box filter (global, proximity-biased by proximity param).
     */
    public Mono<PoiResult> geocodingV5Forward(String query,
            double minLon, double minLat, double maxLon, double maxLat) {
        boolean global = (minLon <= -179 && maxLon >= 179);
        return webClient.get()
                .uri(uriBuilder -> {
                    var b = uriBuilder
                            .path("/geocoding/v5/mapbox.places/{query}.json")
                            .queryParam("limit", 3)
                            .queryParam("types", "poi,address,place")
                            .queryParam("language", "en");
                    if (!global) {
                        b = b.queryParam("bbox", minLon + "," + minLat + "," + maxLon + "," + maxLat);
                    } else {
                        // No bbox: use center of destination as proximity bias
                        double proxLon = (minLon + maxLon) / 2;
                        double proxLat = (minLat + maxLat) / 2;
                        if (Double.isFinite(proxLon) && Double.isFinite(proxLat)) {
                            b = b.queryParam("proximity", proxLon + "," + proxLat);
                        }
                    }
                    return b.build(query);
                })
                .retrieve()
                .bodyToMono(GeocodingV5Response.class)
                .flatMap(resp -> {
                    if (resp == null || resp.getFeatures() == null || resp.getFeatures().isEmpty()) {
                        return Mono.<PoiResult>empty();
                    }
                    for (GeocodingV5Feature f : resp.getFeatures()) {
                        if (f == null) continue;
                        String name = f.getText();
                        if (name == null || name.isBlank()) continue;
                        Geometry geom = f.getGeometry();
                        if (geom == null || geom.getCoordinates() == null
                                || geom.getCoordinates().size() < 2) continue;
                        double lon = geom.getCoordinates().get(0);
                        double lat = geom.getCoordinates().get(1);
                        log.info("[GEOCODING V5] hit: '{}' -> ({}, {})", name, lat, lon);
                        return Mono.just(new PoiResult(name, "attraction", lat, lon));
                    }
                    return Mono.<PoiResult>empty();
                })
                .onErrorResume(e -> {
                    log.warn("[GEOCODING V5] failed for '{}': {}", query, e.getMessage());
                    return Mono.empty();
                });
    }

    private static PoiResult toPoiResult(Feature f, String normalizedSearchCategory) {
        Properties p = f.getProperties();
        if (p == null || p.getName() == null || p.getName().isBlank()) {
            return null;
        }
        Double lat = null;
        Double lon = null;
        if (p.getCoordinates() != null
                && p.getCoordinates().getLatitude() != null
                && p.getCoordinates().getLongitude() != null) {
            lat = p.getCoordinates().getLatitude();
            lon = p.getCoordinates().getLongitude();
        } else if (f.getGeometry() != null
                && f.getGeometry().getCoordinates() != null
                && f.getGeometry().getCoordinates().size() >= 2) {
            lon = f.getGeometry().getCoordinates().get(0);
            lat = f.getGeometry().getCoordinates().get(1);
        }
        if (lat == null || lon == null) {
            return null;
        }

        PoiResult r = new PoiResult(p.getName(), normalizedSearchCategory, lat, lon);
        r.setMapboxId(p.getMapboxId());
        r.setMaki(p.getMaki());
        if (p.getPoiCategoryIds() != null && !p.getPoiCategoryIds().isEmpty()) {
            r.setPoiCategoryIds(List.copyOf(p.getPoiCategoryIds()));
        }
        if (p.getExternalIds() != null && !p.getExternalIds().isEmpty()) {
            r.setExternalIds(Map.copyOf(p.getExternalIds()));
            String fs = p.getExternalIds().get("foursquare");
            if (fs != null && !fs.isBlank()) {
                r.setExternalId(fs.trim());
            }
        }
        return r;
    }

    // ---------- DTOs ----------

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class FeatureCollection {
        private List<Feature> features;
    }

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class Feature {
        private String id;
        private Geometry geometry;
        private Properties properties;
    }

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class Geometry {
        private String type;
        private List<Double> coordinates;
    }

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class Properties {
        private String name;
        @JsonProperty("mapbox_id")
        private String mapboxId;
        private String maki;
        @JsonProperty("poi_category_ids")
        private List<String> poiCategoryIds;
        @JsonProperty("external_ids")
        private Map<String, String> externalIds;
        private Coordinates coordinates;
        private List<Double> bbox;
    }

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class Coordinates {
        private Double latitude;
        private Double longitude;
    }

    /** Suggest endpoint response. */
    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class SuggestResponse {
        private List<Suggestion> suggestions;
    }

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class Suggestion {
        private String name;
        @JsonProperty("mapbox_id")
        private String mapboxId;
        @JsonProperty("feature_type")
        private String featureType;
        private String address;
        @JsonProperty("full_address")
        private String fullAddress;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DestinationGeocodeResult {
        private double centerLat;
        private double centerLon;
        private double minLon;
        private double minLat;
        private double maxLon;
        private double maxLat;
    }

    // ── Geocoding API v5 DTOs ────────────────────────────────────────────────
    // Separate from the Search Box DTOs above; v5 uses "text" instead of "name"
    // and puts coordinates only in geometry (no nested coordinates object).

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class GeocodingV5Response {
        private List<GeocodingV5Feature> features;
    }

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class GeocodingV5Feature {
        /** Short place name, e.g. "Golden Gate Bridge". */
        private String text;
        /** Full name with context, e.g. "Golden Gate Bridge, Presidio, San Francisco…" */
        @JsonProperty("place_name")
        private String placeName;
        /** Feature geometry — reuses the same inner Geometry class (Point with [lon, lat]). */
        private Geometry geometry;
        @JsonProperty("place_type")
        private List<String> placeType;
    }
}

