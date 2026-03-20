package com.vacanza.backend.integration;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.util.List;

@Slf4j
@Component
public class GeoapifyClient {

    private final WebClient webClient;
    private final WebClient geocodeWebClient;

    public GeoapifyClient(
            @Qualifier("geoapifyWebClient") WebClient webClient,
            @Qualifier("geoapifyGeocodeWebClient") WebClient geocodeWebClient) {
        this.webClient = webClient;
        this.geocodeWebClient = geocodeWebClient;
    }

    /**
     * Geocode a place name to coordinates.
     * Returns the first result or Mono.empty() if nothing found.
     */
    public Mono<GeocodeResponse.GeocodeResult> geocode(String placeName) {
        return geocode(placeName, null, null, null);
    }

    /**
     * Geocode a place name with optional bias and country filter for better accuracy.
     * Bias prioritizes results near the given point (e.g. destination city center).
     * Country filter restricts results to a specific country (ISO 3166-1 alpha-2).
     *
     * @param placeName   Address or place to search
     * @param biasLon     Optional longitude for proximity bias
     * @param biasLat     Optional latitude for proximity bias
     * @param countryCode Optional ISO country code (e.g. "tr", "it")
     */
    public Mono<GeocodeResponse.GeocodeResult> geocode(String placeName,
                                                       Double biasLon, Double biasLat,
                                                       String countryCode) {
        return geocodeWebClient.get()
                .uri(uriBuilder -> {
                    var b = uriBuilder
                            .path("/v1/geocode/search")
                            .queryParam("text", placeName)
                            .queryParam("limit", 5);
                    if (countryCode != null && !countryCode.isBlank()) {
                        b.queryParam("filter", "countrycode:" + countryCode.toLowerCase());
                    }
                    if (biasLon != null && biasLat != null) {
                        b.queryParam("bias", "proximity:" + biasLon + "," + biasLat);
                    }
                    return b.build();
                })
                .retrieve()
                .bodyToMono(GeocodeResponse.class)
                .flatMap(resp -> {
                    if (resp.getResults() != null && !resp.getResults().isEmpty()) {
                        return Mono.just(resp.getResults().get(0));
                    }
                    return Mono.empty();
                })
                .doOnError(e -> log.warn("Geocoding failed for '{}': {}", placeName, e.getMessage()))
                .onErrorResume(e -> Mono.empty());
    }

        public Mono<GeoapifyResponse> search(
                        String filter,
                        List<String> categories,
                        int limit) {

                return webClient.get()
                                .uri(uriBuilder -> {
                                        uriBuilder.path("/places");

                                        uriBuilder.queryParam("filter", filter);
                                        uriBuilder.queryParam("limit", limit);

                                        List<String> safeCategories = (categories == null || categories.isEmpty())
                                                        ? List.of("tourism.sights")
                                                        : categories;

                                        uriBuilder.queryParam(
                                                        "categories",
                                                        String.join(",", safeCategories));

                                        return uriBuilder.build();
                                })
                                .retrieve()
                                .bodyToMono(GeoapifyResponse.class);
        }
}
