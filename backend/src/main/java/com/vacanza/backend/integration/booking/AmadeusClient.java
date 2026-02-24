package com.vacanza.backend.integration.booking;

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
import java.util.stream.Collectors;

/**
 * Integration client for Amadeus Self-Service API.
 * Handles hotel search and flight search via a single component.
 */
@Slf4j
@Component
public class AmadeusClient {

    private final WebClient webClient;
    private final AmadeusTokenService tokenService;

    private static final int MAX_HOTEL_IDS = 20;

    public AmadeusClient(
            @Qualifier("amadeusWebClient") WebClient webClient,
            AmadeusTokenService tokenService) {
        this.webClient = webClient;
        this.tokenService = tokenService;
    }

    /**
     * Search for hotel offers in a city.
     *
     * Step 1: GET /v1/reference-data/locations/hotels/by-city → get hotel IDs
     * Step 2: GET /v3/shopping/hotel-offers?hotelIds=... → get offers with prices
     */
    public List<AccommodationOptionDTO> searchHotels(AccommodationSearchRequestDTO request) {
        try {
            // Step 1: Get hotel IDs for the city
            log.info("[AMADEUS] Searching hotels in city: {}", request.getCityCode());

            AmadeusHotelResponse.HotelListResponse hotelList = webClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/v1/reference-data/locations/hotels/by-city")
                            .queryParam("cityCode", request.getCityCode())
                            .build())
                    .header("Authorization", "Bearer " + tokenService.getToken())
                    .retrieve()
                    .bodyToMono(AmadeusHotelResponse.HotelListResponse.class)
                    .block();

            if (hotelList == null || hotelList.getData() == null || hotelList.getData().isEmpty()) {
                log.warn("[AMADEUS] No hotels found for city: {}", request.getCityCode());
                return Collections.emptyList();
            }

            // Take first N hotel IDs to avoid API limits
            String hotelIds = hotelList.getData().stream()
                    .limit(MAX_HOTEL_IDS)
                    .map(AmadeusHotelResponse.HotelEntry::getHotelId)
                    .collect(Collectors.joining(","));

            // Step 2: Get offers for those hotels
            AmadeusHotelResponse offersResponse = webClient.get()
                    .uri(uriBuilder -> uriBuilder
                            .path("/v3/shopping/hotel-offers")
                            .queryParam("hotelIds", hotelIds)
                            .queryParam("checkInDate", request.getCheckInDate().toString())
                            .queryParam("checkOutDate", request.getCheckOutDate().toString())
                            .queryParam("adults", request.getAdults())
                            .queryParam("currency", request.getCurrency())
                            .build())
                    .header("Authorization", "Bearer " + tokenService.getToken())
                    .retrieve()
                    .bodyToMono(AmadeusHotelResponse.class)
                    .block();

            List<AccommodationOptionDTO> results = AmadeusHotelResponse.toAccommodationOptions(offersResponse);
            log.info("[AMADEUS] Found {} hotel offers for city: {}", results.size(), request.getCityCode());
            return results;

        } catch (WebClientResponseException e) {
            log.error("[AMADEUS] Hotel search API error: {} - {}", e.getStatusCode(), e.getResponseBodyAsString());
            return Collections.emptyList();
        } catch (Exception e) {
            log.error("[AMADEUS] Hotel search failed: {}", e.getMessage(), e);
            return Collections.emptyList();
        }
    }

    /**
     * Search for flight offers.
     *
     * GET
     * /v2/shopping/flight-offers?originLocationCode=...&destinationLocationCode=...
     */
    public List<TransportOptionDTO> searchFlights(TransportSearchRequestDTO request) {
        try {
            log.info("[AMADEUS] Searching flights {} -> {}", request.getOrigin(), request.getDestination());

            AmadeusFlightResponse response = webClient.get()
                    .uri(uriBuilder -> {
                        uriBuilder.path("/v2/shopping/flight-offers")
                                .queryParam("originLocationCode", request.getOrigin())
                                .queryParam("destinationLocationCode", request.getDestination())
                                .queryParam("departureDate", request.getDepartureDate().toString())
                                .queryParam("adults", request.getAdults())
                                .queryParam("currencyCode", request.getCurrency())
                                .queryParam("max", 20);

                        if (request.getReturnDate() != null) {
                            uriBuilder.queryParam("returnDate", request.getReturnDate().toString());
                        }

                        return uriBuilder.build();
                    })
                    .header("Authorization", "Bearer " + tokenService.getToken())
                    .retrieve()
                    .bodyToMono(AmadeusFlightResponse.class)
                    .block();

            List<TransportOptionDTO> results = AmadeusFlightResponse.toTransportOptions(response);
            log.info("[AMADEUS] Found {} flight offers {} -> {}", results.size(), request.getOrigin(),
                    request.getDestination());
            return results;

        } catch (WebClientResponseException e) {
            log.error("[AMADEUS] Flight search API error: {} - {}", e.getStatusCode(), e.getResponseBodyAsString());
            return Collections.emptyList();
        } catch (Exception e) {
            log.error("[AMADEUS] Flight search failed: {}", e.getMessage(), e);
            return Collections.emptyList();
        }
    }
}
