package com.vacanza.backend.integration;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

/**
 * Foursquare Places API v3 client.
 * <ul>
 *   <li>{@link #getPlaceDetails(String)} — enrichment (rating, hours, price)</li>
 * </ul>
 *
 * @see <a href="https://docs.foursquare.com/developer/reference/place-details">Foursquare Place Details</a>
 */
@Slf4j
@Component
public class FoursquareClient {

    private final WebClient webClient;

    public FoursquareClient(@Qualifier("foursquareWebClient") WebClient webClient) {
        this.webClient = webClient;
    }

    /**
     * Fetch enrichment data for a single place by its Foursquare ID.
     * Requests only the fields needed for DB enrichment to minimize cost.
     *
     * @param fsqId Foursquare place id (e.g. from Mapbox external_ids.foursquare)
     * @return Place detail with rating, hours, price or empty on error
     */
    public Mono<FoursquareResponse.Place> getPlaceDetails(String fsqId) {
        if (fsqId == null || fsqId.isBlank()) {
            return Mono.empty();
        }

        return webClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/places/{fsqId}")
                        .queryParam("fields", "fsq_id,name,rating,price,hours,location,categories")
                        .build(fsqId))
                .retrieve()
                .bodyToMono(FoursquareResponse.Place.class)
                .doOnError(e -> log.warn("[FOURSQUARE] Place details failed for '{}': {}", fsqId, e.getMessage()))
                .onErrorResume(e -> Mono.empty());
    }
}
