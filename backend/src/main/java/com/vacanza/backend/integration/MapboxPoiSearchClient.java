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
            Map.entry("cafe", "cafe"),
            Map.entry("bar", "bar"),
            Map.entry("nightlife", "nightclub"),
            Map.entry("nightclub", "nightclub"),
            Map.entry("pub", "pub"),
            Map.entry("food", "restaurant"),
            Map.entry("neighborhood", "neighborhood"),
            Map.entry("ruins", "historic_site")
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
                        .queryParam("types", "poi")
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
     * High-level resolver: tries forward search → expanded bbox → suggest+retrieve.
     * Returns coordinates for a place name, guaranteed to try every strategy.
     */
    public Mono<PoiResult> resolvePlace(String placeName, String destination,
            double minLon, double minLat, double maxLon, double maxLat) {
        String query = placeName.contains(",") ? placeName : placeName + ", " + destination;

        // Step 1: forward search in bbox (EN)
        return forwardSearchPoi(query, minLon, minLat, maxLon, maxLat)
                .flatMap(results -> results.isEmpty() ? Mono.<PoiResult>empty() : Mono.just(results.get(0)))
                .doOnNext(r -> log.info("[RESOLVE] Step 1 (forward/bbox) hit for '{}'", placeName))

                // Step 2: forward search with expanded bbox (+50%)
                .switchIfEmpty(Mono.defer(() -> {
                    double latRange = (maxLat - minLat) * 0.5;
                    double lonRange = (maxLon - minLon) * 0.5;
                    log.info("[RESOLVE] Step 2 (forward/expanded-bbox) for '{}'", placeName);
                    return forwardSearchPoi(query,
                            minLon - lonRange, minLat - latRange,
                            maxLon + lonRange, maxLat + latRange)
                            .flatMap(r -> r.isEmpty() ? Mono.<PoiResult>empty() : Mono.just(r.get(0)));
                }))

                // Step 3: suggest+retrieve (fuzzy matching, no bbox constraint)
                .switchIfEmpty(Mono.defer(() -> {
                    log.info("[RESOLVE] Step 3 (suggest+retrieve) for '{}'", placeName);
                    double proxLon = (minLon + maxLon) / 2;
                    double proxLat = (minLat + maxLat) / 2;
                    return suggestAndRetrieve(query, proxLon, proxLat);
                }))

                // Step 4: forward search without bbox (global, proximity-biased)
                .switchIfEmpty(Mono.defer(() -> {
                    log.info("[RESOLVE] Step 4 (forward/no-bbox) for '{}'", placeName);
                    return forwardSearchPoiWithProximity(query,
                            (minLon + maxLon) / 2, (minLat + maxLat) / 2);
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
     * /suggest finds candidates with fuzzy matching (handles multilingual names),
     * /retrieve fetches exact coordinates for the best match.
     */
    public Mono<PoiResult> suggestAndRetrieve(String query, double proxLon, double proxLat) {
        String sessionToken = java.util.UUID.randomUUID().toString();
        return webClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/search/searchbox/v1/suggest")
                        .queryParam("q", query)
                        .queryParam("limit", 3)
                        .queryParam("types", "poi")
                        .queryParam("proximity", proxLon + "," + proxLat)
                        .queryParam("language", "en")
                        .queryParam("session_token", sessionToken)
                        .build())
                .retrieve()
                .bodyToMono(SuggestResponse.class)
                .flatMap(resp -> {
                    if (resp == null || resp.getSuggestions() == null || resp.getSuggestions().isEmpty()) {
                        return Mono.empty();
                    }
                    // Pick the first POI suggestion
                    Suggestion best = null;
                    for (Suggestion s : resp.getSuggestions()) {
                        if (s != null && s.getMapboxId() != null && !s.getMapboxId().isBlank()) {
                            if ("poi".equals(s.getFeatureType())) {
                                best = s;
                                break;
                            }
                            if (best == null) {
                                best = s; // fallback to any type
                            }
                        }
                    }
                    if (best == null) return Mono.empty();
                    String mapboxId = best.getMapboxId();
                    log.info("[SUGGEST] best match for '{}': name='{}', id={}", query,
                            best.getName(), mapboxId);
                    return retrieveByMapboxId(mapboxId, sessionToken);
                })
                .onErrorResume(e -> {
                    log.warn("[SUGGEST+RETRIEVE] failed for '{}': {}", query, e.getMessage());
                    return Mono.empty();
                });
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
}

