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

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

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
    private static final int HOTEL_BATCH_SIZE = 5;

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
     * (batched to handle partial availability in Amadeus test tier)
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

            // Take first N hotel IDs
            List<String> allHotelIds = hotelList.getData().stream()
                    .limit(MAX_HOTEL_IDS)
                    .map(AmadeusHotelResponse.HotelEntry::getHotelId)
                    .toList();

            // Step 2: Get offers in batches (Amadeus test tier returns 400 if any
            // hotel in the batch has no availability, so smaller batches
            // yield partial results instead of total failure)
            List<AccommodationOptionDTO> allResults = new ArrayList<>();
            for (int i = 0; i < allHotelIds.size(); i += HOTEL_BATCH_SIZE) {
                List<String> batch = allHotelIds.subList(i,
                        Math.min(i + HOTEL_BATCH_SIZE, allHotelIds.size()));
                String hotelIds = String.join(",", batch);

                try {
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

                    allResults.addAll(AmadeusHotelResponse.toAccommodationOptions(
                            offersResponse, request.getCheckInDate(), request.getCheckOutDate()));
                } catch (WebClientResponseException e) {
                    log.warn("[AMADEUS] Hotel offers batch failed ({}): {}", hotelIds, e.getStatusCode());
                    // Continue with next batch
                } catch (Exception e) {
                    log.warn("[AMADEUS] Hotel offers batch error ({}): {}", hotelIds, e.getMessage());
                }
            }

            log.info("[AMADEUS] Found {} hotel offers for city: {}", allResults.size(), request.getCityCode());
            return allResults;

        } catch (WebClientResponseException e) {
            log.error("[AMADEUS] Hotel list API error: {} - {}", e.getStatusCode(), e.getResponseBodyAsString());
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
