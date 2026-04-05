package com.vacanza.backend.integration.event;

import com.vacanza.backend.component.ApiMetricsCollector;
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
 * Uses the US Discovery API v2:
 * {@code GET /discovery/v2/events.json?...}
 * <p>
 * Official reference: <a href="https://developer.ticketmaster.com/products-and-docs/apis/discovery-api/v2/">Discovery API v2</a>.
 * Implementation notes:
 * <ul>
 *   <li>{@code classificationName} is an <strong>array</strong> (explode) in the OpenAPI spec — send one query param per
 *       value, not a single comma-joined string.</li>
 *   <li>{@code latlong} is <strong>deprecated</strong>; prefer {@code geoPoint} with the same {@code lat,lon} format.</li>
 *   <li>{@code startDateTime} / {@code endDateTime} filter by event <em>start</em> time; use ISO-8601. Appending {@code Z}
 *       without converting from the trip locale can shift the window (see TM docs for examples).</li>
 *   <li>European inventory may be limited on the US Discovery host; Ticketmaster documents a separate International product.</li>
 *   <li>When both {@code city} and {@code countryCode} are set, do not send {@code geoPoint} — combining them tends to
 *       over-narrow results (e.g. one hit for İzmir); prefer city+country for metro-level discovery.</li>
 * </ul>
 */
@Slf4j
@Component
public class TicketmasterClient {

    private static final String API_NAME = "Ticketmaster";

    private final WebClient webClient;
    private final TicketmasterProperties properties;
    private final ApiMetricsCollector metricsCollector;

    public TicketmasterClient(
            @Qualifier("ticketmasterWebClient") WebClient webClient,
            TicketmasterProperties properties,
            ApiMetricsCollector metricsCollector) {
        this.webClient = webClient;
        this.properties = properties;
        this.metricsCollector = metricsCollector;
    }

    /**
     * Search for events using the Ticketmaster Discovery API.
     *
     * @param request event search parameters
     * @return list of events matching the search criteria
     */
    public List<EventDTO> searchEvents(EventSearchRequestDTO request) {
        boolean cityAndCountry = request.getCity() != null && !request.getCity().isBlank()
                && request.getCountryCode() != null && !request.getCountryCode().isBlank();
        boolean useGeo = request.getGeoLatitude() != null && request.getGeoLongitude() != null && !cityAndCountry;

        String geoLog = null;
        if (request.getGeoLatitude() != null && request.getGeoLongitude() != null) {
            geoLog = useGeo
                    ? request.getGeoLatitude() + "," + request.getGeoLongitude()
                    : "skipped (city+country set)";
        }

        log.info("[TICKETMASTER] Searching events: city={}, country={}, geoPoint={}, dates={}/{}, category={}",
                request.getCity(),
                request.getCountryCode(),
                geoLog,
                request.getStartDate(), request.getEndDate(),
                request.getCategory());

        long startTime = System.currentTimeMillis();
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

                        // Geo: only when city/country missing — with both, TM+geoPoint over-narrows (AND semantics)
                        if (useGeo) {
                            builder.queryParam("geoPoint", request.getGeoLatitude() + "," + request.getGeoLongitude());
                            builder.queryParam("radius", "50");
                            builder.queryParam("unit", "km");
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

                        // classificationName: OpenAPI type is array (explode) — one query param per segment name
                        if (request.getCategory() != null && !request.getCategory().isBlank()) {
                            for (String segment : request.getCategory().split(",")) {
                                String name = segment.trim();
                                if (!name.isEmpty()) {
                                    builder.queryParam("classificationName", name);
                                }
                            }
                        }

                        // Sort by date ascending for travel planning relevance
                        builder.queryParam("sort", "date,asc");

                        return builder.build();
                    })
                    .retrieve()
                    .bodyToMono(TicketmasterResponse.class)
                    .block();

            List<EventDTO> results = TicketmasterResponse.toEventDTOs(response);

            metricsCollector.recordCall(API_NAME, System.currentTimeMillis() - startTime);
            log.info("[TICKETMASTER] Event search returned {} results", results.size());
            return results;

        } catch (WebClientResponseException e) {
            metricsCollector.recordError(API_NAME);
            metricsCollector.recordCall(API_NAME, System.currentTimeMillis() - startTime);
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
            metricsCollector.recordError(API_NAME);
            log.error("[TICKETMASTER] Event search failed: {}", e.getMessage(), e);
            throw new EventException(
                    "Event search failed: " + e.getMessage(),
                    HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
}
