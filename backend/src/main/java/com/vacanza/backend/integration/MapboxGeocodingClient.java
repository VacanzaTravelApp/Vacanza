package com.vacanza.backend.integration;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.util.List;

/**
 * Mapbox Search Box API v1 client.
 * Replaces Geocoding v5/v6 for geocoding waypoints, as POI search is exclusively supported here.
 *
 * @see <a href="https://docs.mapbox.com/api/search/search-box/">Mapbox Search Box API</a>
 */
@Slf4j
@Component
public class MapboxGeocodingClient {

    private final WebClient webClient;

    public MapboxGeocodingClient(
            @Qualifier("mapboxGeocodingWebClient") WebClient webClient) {
        this.webClient = webClient;
    }

    /**
     * Geocode a place name to coordinates (no bias, no country filter).
     */
    public Mono<GeocodingResult> geocode(String placeName) {
        return geocode(placeName, null, null, null);
    }

    /**
     * Geocode a place name with optional proximity bias and country filter.
     * Uses Search Box API v1 which fully supports POI searches.
     *
     * @param placeName   Address or place to search
     * @param biasLon     Optional longitude for proximity bias
     * @param biasLat     Optional latitude for proximity bias
     * @param countryCode Optional ISO 3166-1 alpha-2 country code (e.g. "TR", "IT")
     */
    public Mono<GeocodingResult> geocode(String placeName,
            Double biasLon, Double biasLat,
            String countryCode) {
        return webClient.get()
                .uri(uriBuilder -> {
                    var b = uriBuilder
                            .path("/search/searchbox/v1/forward")
                            .queryParam("q", placeName)
                            .queryParam("limit", 1)
                            .queryParam("language", "en")
                            // Restrict to POIs and addresses to improve accuracy
                            .queryParam("types", "poi,address");
                            
                    if (countryCode != null && !countryCode.isBlank()) {
                        b.queryParam("country", countryCode.toUpperCase());
                    }
                    if (biasLon != null && biasLat != null) {
                        b.queryParam("proximity", biasLon + "," + biasLat);
                    }
                    return b.build();
                })
                .retrieve()
                .bodyToMono(MapboxSearchBoxResponse.class)
                .flatMap(resp -> {
                    if (resp.getFeatures() != null && !resp.getFeatures().isEmpty()) {
                        var feature = resp.getFeatures().get(0);
                        var result = toResult(feature);
                        log.info("Mapbox SearchBox '{}' -> lat={}, lon={}, formatted={}",
                                placeName, result.getLat(), result.getLon(), result.getFormattedName());
                        return Mono.just(result);
                    }
                    log.warn("Mapbox SearchBox: no results for '{}'", placeName);
                    return Mono.empty();
                })
                .doOnError(e -> log.warn("Mapbox SearchBox failed for '{}': {}", placeName, e.getMessage()))
                .onErrorResume(e -> Mono.empty());
    }

    private GeocodingResult toResult(MapboxFeature feature) {
        var result = new GeocodingResult();
        if (feature.getGeometry() != null && feature.getGeometry().getCoordinates() != null
                && feature.getGeometry().getCoordinates().size() >= 2) {
            result.setLon(feature.getGeometry().getCoordinates().get(0));
            result.setLat(feature.getGeometry().getCoordinates().get(1));
        }
        if (feature.getProperties() != null) {
            result.setFormattedName(feature.getProperties().getFullAddress());
            
            // country_code is nested: properties.context.country.country_code
            var ctx = feature.getProperties().getContext();
            if (ctx != null && ctx.getCountry() != null) {
                result.setCountryCode(ctx.getCountry().getCountryCode());
            }
        }
        return result;
    }

    // ---------- Response DTOs ----------

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class MapboxSearchBoxResponse {
        private List<MapboxFeature> features;
    }

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class MapboxFeature {
        private MapboxGeometry geometry;
        private MapboxProperties properties;
    }

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class MapboxGeometry {
        private String type;
        private List<Double> coordinates; // [lon, lat]
    }

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class MapboxProperties {
        @JsonProperty("full_address")
        private String fullAddress;

        private String name;

        private MapboxContext context;
    }

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class MapboxContext {
        private MapboxCountryContext country;
    }

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class MapboxCountryContext {
        @JsonProperty("country_code")
        private String countryCode; // ISO 3166-1 alpha-2 (e.g. "IT")

        private String name;
    }

    /**
     * Simplified geocoding result with coordinates and metadata.
     * Used by ChatProxyController to set waypoint lat/lon.
     */
    @Data
    @NoArgsConstructor
    public static class GeocodingResult {
        private double lat;
        private double lon;
        private String formattedName;
        private String countryCode; // ISO 3166-1 alpha-2
    }
}
