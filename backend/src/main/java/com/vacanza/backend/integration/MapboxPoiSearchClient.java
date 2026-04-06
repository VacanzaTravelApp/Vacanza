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
