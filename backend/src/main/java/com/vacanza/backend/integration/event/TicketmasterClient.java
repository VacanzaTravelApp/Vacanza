package com.vacanza.backend.integration.event;

import com.vacanza.backend.config.TicketmasterProperties;
import com.vacanza.backend.dto.request.EventSearchRequestDTO;
import com.vacanza.backend.dto.response.EventDTO;
import com.vacanza.backend.exceptions.EventException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Ticketmaster Discovery API integration client.
 *
 * Uses the Discovery API v2:
 *   GET /events.json?apikey=...&city=...&startDateTime=...&classificationName=...
 *
 * API docs: https://developer.ticketmaster.com/products-and-docs/apis/discovery-api/v2/
 */
@Slf4j
@Component
public class TicketmasterClient {

    private final WebClient webClient;
    private final TicketmasterProperties properties;

    public TicketmasterClient(
            @Qualifier("ticketmasterWebClient") WebClient webClient,
            TicketmasterProperties properties) {
        this.webClient = webClient;
        this.properties = properties;
    }

    /**
     * Search for events using the Ticketmaster Discovery API.
     *
     * @param request event search parameters
     * @return list of events matching the search criteria
     */
    public List<EventDTO> searchEvents(EventSearchRequestDTO request) {
        log.info("[TICKETMASTER] Searching events: city={}, dates={}/{}, category={}",
                request.getCity(), request.getStartDate(), request.getEndDate(),
                request.getCategory());

        try {
            TicketmasterResponse response = webClient.get()
                    .uri(uriB -> {
                        var builder = uriB.path("/events.json")
                                .queryParam("apikey", properties.getApiKey())
                                .queryParam("city", request.getCity())
                                .queryParam("size", request.getSize() != null
                                        ? Math.min(request.getSize(), 50) : 20);

                        // Country filter
                        if (request.getCountryCode() != null && !request.getCountryCode().isBlank()) {
                            builder.queryParam("countryCode", request.getCountryCode());
                        }

                        // Date range filter — Ticketmaster expects ISO 8601 with 'Z':
                        // e.g. "2026-04-01T00:00:00Z"
                        if (request.getStartDate() != null) {
                            String startDateTime = request.getStartDate()
                                    .atTime(LocalTime.MIN)
                                    .format(DateTimeFormatter.ISO_LOCAL_DATE_TIME) + "Z";
                            builder.queryParam("startDateTime", startDateTime);
                        }
                        if (request.getEndDate() != null) {
                            String endDateTime = request.getEndDate()
                                    .atTime(LocalTime.MAX)
                                    .format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss")) + "Z";
                            builder.queryParam("endDateTime", endDateTime);
                        }

                        // Category filter (e.g., "music", "sports", "arts")
                        if (request.getCategory() != null && !request.getCategory().isBlank()) {
                            builder.queryParam("classificationName", request.getCategory());
                        }

                        // Sort by date ascending for travel planning relevance
                        builder.queryParam("sort", "date,asc");

                        return builder.build();
                    })
                    .retrieve()
                    .bodyToMono(TicketmasterResponse.class)
                    .block();

            List<EventDTO> results = TicketmasterResponse.toEventDTOs(response);

            log.info("[TICKETMASTER] Event search returned {} results", results.size());
            return results;

        } catch (WebClientResponseException e) {
            log.error("[TICKETMASTER] Event search API error: {} - {}",
                    e.getStatusCode(), e.getResponseBodyAsString());

            if (e.getStatusCode() == HttpStatus.UNAUTHORIZED
                    || e.getStatusCode() == HttpStatus.FORBIDDEN) {
                throw new EventException(
                        "Ticketmaster authentication failed — check TICKETMASTER_API_KEY",
                        HttpStatus.INTERNAL_SERVER_ERROR);
            }
            if (e.getStatusCode() == HttpStatus.TOO_MANY_REQUESTS) {
                throw new EventException(
                        "Ticketmaster rate limit exceeded — please try again later",
                        HttpStatus.SERVICE_UNAVAILABLE);
            }
            throw new EventException(
                    "Event search unavailable: " + e.getStatusCode(),
                    HttpStatus.BAD_GATEWAY);

        } catch (EventException e) {
            throw e;
        } catch (Exception e) {
            log.error("[TICKETMASTER] Event search failed: {}", e.getMessage(), e);
            throw new EventException(
                    "Event search failed: " + e.getMessage(),
                    HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}
