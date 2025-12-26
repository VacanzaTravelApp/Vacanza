package com.vacanza.backend.integration;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

@Component
@RequiredArgsConstructor
public class FoursquarePlacesClient {

    private final WebClient foursquareWebClient;

    public FsqPlacesSearchResponse searchByBbox(double minLat, double minLng, double maxLat, double maxLng, int limit) {
        // Foursquare: sw=lat,lng & ne=lat,lng
        String sw = minLat + "," + minLng;
        String ne = maxLat + "," + maxLng;

        return foursquareWebClient.get()
                .uri(uri -> uri
                        .path("/places/search")
                        .queryParam("sw", sw)
                        .queryParam("ne", ne)
                        .queryParam("limit", Math.min(limit, 50)) // Foursquare genelde 50 limit
                        .queryParam("fields", "fsq_id,name,categories,geocodes,rating,price")
                        .build())
                .retrieve()
                .bodyToMono(FsqPlacesSearchResponse.class)
                .block();
    }
}