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
 */
@Slf4j
@Component
public class MapboxPoiSearchClient {

    private final WebClient webClient;

    // Mapbox canonical category IDs used by Search Box category search.
    private static final Map<String, String> CATEGORY_MAP = Map.ofEntries(
            Map.entry("museum", "museum"),
            Map.entry("monument", "monument"),
            Map.entry("historic_site", "historic_site"),
            Map.entry("church", "place_of_worship"),
            Map.entry("park", "park"),
            Map.entry("art_gallery", "art_gallery"),
            Map.entry("restaurant", "restaurant"),
            Map.entry("market", "market"),
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
                        .queryParam("limit", 1)
                        .queryParam("language", "en")
                        .build())
                .retrieve()
                .bodyToMono(FeatureCollection.class)
                .flatMap(resp -> {
                    if (resp == null || resp.getFeatures() == null || resp.getFeatures().isEmpty()) {
                        return Mono.empty();
                    }
                    Feature f = resp.getFeatures().get(0);
                    if (f.getProperties() == null) return Mono.empty();
                    List<Double> bbox = f.getProperties().getBbox();
                    Coordinates c = f.getProperties().getCoordinates();
                    if (bbox == null || bbox.size() != 4 || c == null
                            || c.getLatitude() == null || c.getLongitude() == null) {
                        return Mono.empty();
                    }
                    return Mono.just(new DestinationGeocodeResult(
                            c.getLatitude(), c.getLongitude(),
                            bbox.get(0), bbox.get(1), bbox.get(2), bbox.get(3)
                    ));
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
                        .queryParam("limit", 10)
                        .queryParam("language", "en")
                        .build(mapboxCategory))
                .retrieve()
                .bodyToMono(FeatureCollection.class)
                .map(resp -> {
                    if (resp == null || resp.getFeatures() == null) return List.<PoiResult>of();
                    return resp.getFeatures().stream()
                            .filter(f -> f != null && f.getProperties() != null && f.getProperties().getName() != null)
                            .map(f -> {
                                Coordinates c = f.getProperties().getCoordinates();
                                if (c == null || c.getLatitude() == null || c.getLongitude() == null) return null;
                                return new PoiResult(
                                        f.getProperties().getName(),
                                        normalized,
                                        c.getLatitude(),
                                        c.getLongitude()
                                );
                            })
                            .filter(x -> x != null)
                            .toList();
                })
                .onErrorResume(e -> Mono.just(List.of()));
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
        private Properties properties;
    }

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    private static class Properties {
        private String name;
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

