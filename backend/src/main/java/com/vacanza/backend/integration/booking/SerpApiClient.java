package com.vacanza.backend.integration.booking;

import com.vacanza.backend.config.SerpApiProperties;
import com.vacanza.backend.dto.request.AccommodationSearchRequestDTO;
import com.vacanza.backend.dto.request.TransportSearchRequestDTO;
import com.vacanza.backend.dto.response.AccommodationOptionDTO;
import com.vacanza.backend.dto.response.TransportOptionDTO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.util.Collections;
import java.util.List;

/**
 * SerpApi integration client for Google Hotels and Google Flights search.
 *
 * Uses SerpApi's scraping APIs:
 * - Google Hotels: GET /search.json?engine=google_hotels&q=...
 * - Google Flights: GET /search.json?engine=google_flights&departure_id=...
 *
 * Replaces the previous AmadeusClient + AmadeusTokenService.
 */
@Slf4j
@Component
public class SerpApiClient {

    private final WebClient webClient;
    private final SerpApiProperties properties;

    public SerpApiClient(
            @Qualifier("serpApiWebClient") WebClient webClient,
            SerpApiProperties properties) {
        this.webClient = webClient;
        this.properties = properties;
    }

    /**
     * Search for hotels using Google Hotels via SerpApi.
     *
     * @param request accommodation search parameters
     * @return normalized list of hotel options
     */
    public List<AccommodationOptionDTO> searchHotels(AccommodationSearchRequestDTO request) {
        log.info("[SERPAPI] Searching hotels: query={}, dates={}/{}",
                request.getQuery(), request.getCheckInDate(), request.getCheckOutDate());

        try {
            var uriBuilder = webClient.get()
                    .uri(uriB -> {
                        var builder = uriB.path("/search.json")
                                .queryParam("engine", "google_hotels")
                                .queryParam("q", request.getQuery())
                                .queryParam("check_in_date", request.getCheckInDate().toString())
                                .queryParam("check_out_date", request.getCheckOutDate().toString())
                                .queryParam("adults", request.getAdults())
                                .queryParam("currency", request.getCurrency())
                                .queryParam("gl", "us")
                                .queryParam("hl", "en")
                                .queryParam("api_key", properties.getApiKey());

                        if (request.getBudget() != null) {
                            builder.queryParam("max_price", request.getBudget().intValue());
                        }

                        return builder.build();
                    });

            SerpApiHotelResponse response = uriBuilder
                    .retrieve()
                    .bodyToMono(SerpApiHotelResponse.class)
                    .block();

            List<AccommodationOptionDTO> results = SerpApiHotelResponse.toAccommodationOptions(response,
                    request.getCurrency());

            log.info("[SERPAPI] Hotel search returned {} results", results.size());
            return results;

        } catch (WebClientResponseException e) {
            log.error("[SERPAPI] Hotel search API error: {} - {}",
                    e.getStatusCode(), e.getResponseBodyAsString());
            return Collections.emptyList();
        } catch (Exception e) {
            log.error("[SERPAPI] Hotel search failed: {}", e.getMessage(), e);
            return Collections.emptyList();
        }
    }

    /**
     * Search for flights using Google Flights via SerpApi.
     *
     * @param request transport search parameters
     * @return normalized list of flight options
     */
    public List<TransportOptionDTO> searchFlights(TransportSearchRequestDTO request) {
        log.info("[SERPAPI] Searching flights: {}->{}, date={}",
                request.getOrigin(), request.getDestination(), request.getDepartureDate());

        try {
            // Determine flight type
            String type = request.getReturnDate() != null ? "1" : "2"; // 1=Round trip, 2=One way

            SerpApiFlightResponse response = webClient.get()
                    .uri(uriB -> {
                        var builder = uriB.path("/search.json")
                                .queryParam("engine", "google_flights")
                                .queryParam("departure_id", request.getOrigin())
                                .queryParam("arrival_id", request.getDestination())
                                .queryParam("outbound_date", request.getDepartureDate().toString())
                                .queryParam("type", type)
                                .queryParam("adults", request.getAdults())
                                .queryParam("currency", request.getCurrency())
                                .queryParam("hl", "en")
                                .queryParam("api_key", properties.getApiKey());

                        if (request.getReturnDate() != null) {
                            builder.queryParam("return_date",
                                    request.getReturnDate().toString());
                        }

                        return builder.build();
                    })
                    .retrieve()
                    .bodyToMono(SerpApiFlightResponse.class)
                    .block();

            List<TransportOptionDTO> results = SerpApiFlightResponse.toTransportOptions(response,
                    request.getCurrency());

            log.info("[SERPAPI] Flight search returned {} results", results.size());
            return results;

        } catch (WebClientResponseException e) {
            log.error("[SERPAPI] Flight search API error: {} - {}",
                    e.getStatusCode(), e.getResponseBodyAsString());
            return Collections.emptyList();
        } catch (Exception e) {
            log.error("[SERPAPI] Flight search failed: {}", e.getMessage(), e);
            return Collections.emptyList();
        }
    }
}
