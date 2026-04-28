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
import java.util.Map;

/**
 * Ticketmaster event search client.
 *
 * Routes requests to one of two Ticketmaster APIs based on destination country:
 * <ul>
 *   <li><strong>US Discovery API</strong> ({@code app.ticketmaster.com/discovery/v2}) — US, Canada, UK, Ireland,
 *       Australia, NZ, Turkey, and any country not covered by the EU API.</li>
 *   <li><strong>International Discovery API</strong> ({@code app.ticketmaster.eu/mfxapi/v2}) — Germany, Austria,
 *       Netherlands, Denmark, Belgium, Norway, Switzerland, Spain, Sweden, Finland, Poland.
 *       Uses {@code domain} parameter instead of {@code countryCode}, and {@code lat}/{@code long} for geo search.</li>
 * </ul>
 *
 * Official references:
 * <ul>
 *   <li><a href="https://developer.ticketmaster.com/products-and-docs/apis/discovery-api/v2/">US Discovery API v2</a></li>
 *   <li><a href="https://developer.ticketmaster.com/products-and-docs/apis/international-discovery/v2/">International Discovery API v2</a></li>
 * </ul>
 */
@Slf4j
@Component
public class TicketmasterClient {

    /**
     * ISO 3166-1 alpha-2 → Ticketmaster EU domain name.
     * Only countries served by app.ticketmaster.eu/mfxapi/v2 are listed here.
     */
    private static final Map<String, String> EU_COUNTRY_TO_DOMAIN = Map.ofEntries(
            Map.entry("DE", "germany"),
            Map.entry("AT", "austria"),
            Map.entry("NL", "netherlands"),
            Map.entry("DK", "denmark"),
            Map.entry("BE", "belgium"),
            Map.entry("NO", "norway"),
            Map.entry("CH", "switzerland"),
            Map.entry("ES", "spain"),
            Map.entry("SE", "sweden"),
            Map.entry("FI", "finland"),
            Map.entry("PL", "poland")
    );

    /**
     * Countries with confirmed strong inventory on app.ticketmaster.com.
     * All other countries use geo-only search on the US API to avoid empty results
     * from a countryCode filter on markets where TM has no indexed inventory.
     */
    private static final java.util.Set<String> STRONG_US_COVERAGE = java.util.Set.of(
            "US", "CA", "MX", "GB", "IE", "AU", "NZ"
    );

    private final WebClient webClient;
    private final WebClient euWebClient;
    private final TicketmasterProperties properties;

    public TicketmasterClient(
            @Qualifier("ticketmasterWebClient") WebClient webClient,
            @Qualifier("ticketmasterEuWebClient") WebClient euWebClient,
            TicketmasterProperties properties) {
        this.webClient = webClient;
        this.euWebClient = euWebClient;
        this.properties = properties;
    }

    /**
     * Search for events. Automatically routes to the EU API for European markets
     * (DE, AT, NL, DK, BE, NO, CH, ES, SE, FI, PL) and falls back to the US API
     * for all other destinations.
     */
    public List<EventDTO> searchEvents(EventSearchRequestDTO request) {
        String euDomain = resolveEuDomain(request.getCountryCode());
        if (euDomain != null) {
            return searchEventsEu(request, euDomain);
        }
        return searchEventsUs(request);
    }

    private static String resolveEuDomain(String countryCode) {
        if (countryCode == null || countryCode.isBlank()) {
            return null;
        }
        return EU_COUNTRY_TO_DOMAIN.get(countryCode.trim().toUpperCase());
    }

    // ──────────────────────────────────────────────────────────────
    // US Discovery API  (app.ticketmaster.com/discovery/v2)
    // ──────────────────────────────────────────────────────────────

    private List<EventDTO> searchEventsUs(EventSearchRequestDTO request) {
        String countryCode = request.getCountryCode();
        boolean strongCoverage = countryCode != null
                && STRONG_US_COVERAGE.contains(countryCode.trim().toUpperCase());

        // For countries without confirmed TM inventory, skip countryCode and rely on
        // geo coordinates so we don't get zero results from an empty country filter.
        boolean useCountry = strongCoverage;
        boolean hasGeo = request.getGeoLatitude() != null && request.getGeoLongitude() != null;

        // City+country: only when country has confirmed coverage; prefer geo otherwise.
        boolean cityAndCountry = request.getCity() != null && !request.getCity().isBlank()
                && useCountry;
        boolean useGeo = hasGeo && !cityAndCountry;

        String geoLog = hasGeo
                ? (useGeo ? request.getGeoLatitude() + "," + request.getGeoLongitude()
                          : "skipped (city+country set)")
                : null;

        log.info("[TICKETMASTER] US search: city={}, country={} (strongCoverage={}), geoPoint={}, dates={}/{}",
                request.getCity(), countryCode, strongCoverage, geoLog,
                request.getStartDate(), request.getEndDate());

        try {
            TicketmasterResponse response = webClient.get()
                    .uri(uriB -> {
                        var builder = uriB.path("/events.json")
                                .queryParam("apikey", properties.getApiKey())
                                .queryParam("size", request.getSize() != null
                                        ? Math.min(request.getSize(), 50) : 20);

                        // Send city only when using country filter (strong-coverage path)
                        if (cityAndCountry) {
                            builder.queryParam("city", request.getCity());
                            builder.queryParam("countryCode", countryCode);
                        }

                        // Geo: preferred for non-strong-coverage countries, or when no country set
                        if (useGeo) {
                            builder.queryParam("geoPoint",
                                    request.getGeoLatitude() + "," + request.getGeoLongitude());
                            builder.queryParam("radius", "50");
                            builder.queryParam("unit", "km");
                        }

                        // Fallback: city only (no country, no geo) — last resort
                        if (!cityAndCountry && !useGeo && request.getCity() != null
                                && !request.getCity().isBlank()) {
                            builder.queryParam("city", request.getCity());
                        }

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

                        // classificationName is an array (explode) in the OpenAPI spec
                        if (request.getCategory() != null && !request.getCategory().isBlank()) {
                            for (String segment : request.getCategory().split(",")) {
                                String name = segment.trim();
                                if (!name.isEmpty()) {
                                    builder.queryParam("classificationName", name);
                                }
                            }
                        }

                        builder.queryParam("sort", "date,asc");
                        return builder.build();
                    })
                    .retrieve()
                    .bodyToMono(TicketmasterResponse.class)
                    .block();

            List<EventDTO> results = TicketmasterResponse.toEventDTOs(response);
            log.info("[TICKETMASTER] US search returned {} results", results.size());
            return results;

        } catch (WebClientResponseException e) {
            log.error("[TICKETMASTER] US search API error: {} - {}",
                    e.getStatusCode(), e.getResponseBodyAsString());
            throw translateHttpError("[TICKETMASTER]", e);
        } catch (EventException e) {
            throw e;
        } catch (Exception e) {
            log.error("[TICKETMASTER] US search failed: {}", e.getMessage(), e);
            throw new EventException("Event search failed: " + e.getMessage(),
                    HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // ──────────────────────────────────────────────────────────────
    // International Discovery API  (app.ticketmaster.eu/mfxapi/v2)
    // ──────────────────────────────────────────────────────────────

    private List<EventDTO> searchEventsEu(EventSearchRequestDTO request, String domain) {
        boolean hasGeo = request.getGeoLatitude() != null && request.getGeoLongitude() != null;

        log.info("[TICKETMASTER-EU] EU search: domain={}, city={}, geo={}, dates={}/{}",
                domain, request.getCity(),
                hasGeo ? request.getGeoLatitude() + "," + request.getGeoLongitude() : "none",
                request.getStartDate(), request.getEndDate());

        try {
            TicketmasterEuResponse response = euWebClient.get()
                    .uri(uriB -> {
                        var builder = uriB.path("/events")
                                .queryParam("apikey", properties.getApiKey())
                                .queryParam("domain", domain)
                                .queryParam("rows", request.getSize() != null
                                        ? Math.min(request.getSize(), 50) : 20);

                        // EU API uses lat/long for geo search; no city-name parameter exists
                        if (hasGeo) {
                            builder.queryParam("lat", request.getGeoLatitude());
                            builder.queryParam("long", request.getGeoLongitude());
                            builder.queryParam("radius", "50");
                        }

                        // EU API date params: eventdate_from / eventdate_to (ISO 8601 with Z)
                        if (request.getStartDate() != null) {
                            String from = request.getStartDate()
                                    .atTime(LocalTime.MIN)
                                    .format(DateTimeFormatter.ISO_LOCAL_DATE_TIME) + "Z";
                            builder.queryParam("eventdate_from", from);
                        }
                        if (request.getEndDate() != null) {
                            String to = request.getEndDate()
                                    .atTime(LocalTime.MAX)
                                    .format(DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss")) + "Z";
                            builder.queryParam("eventdate_to", to);
                        }

                        builder.queryParam("sort_by", "eventdate");
                        builder.queryParam("order", "asc");
                        return builder.build();
                    })
                    .retrieve()
                    .bodyToMono(TicketmasterEuResponse.class)
                    .block();

            List<EventDTO> results = TicketmasterEuResponse.toEventDTOs(response);
            log.info("[TICKETMASTER-EU] EU search returned {} results", results.size());
            return results;

        } catch (WebClientResponseException e) {
            log.error("[TICKETMASTER-EU] EU search API error: {} - {}",
                    e.getStatusCode(), e.getResponseBodyAsString());
            throw translateHttpError("[TICKETMASTER-EU]", e);
        } catch (EventException e) {
            throw e;
        } catch (Exception e) {
            log.error("[TICKETMASTER-EU] EU search failed: {}", e.getMessage(), e);
            throw new EventException("Event search failed: " + e.getMessage(),
                    HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    // ──────────────────────────────────────────────────────────────

    private static EventException translateHttpError(String tag, WebClientResponseException e) {
        if (e.getStatusCode() == HttpStatus.UNAUTHORIZED
                || e.getStatusCode() == HttpStatus.FORBIDDEN) {
            return new EventException(
                    tag + " authentication failed — check TICKETMASTER_API_KEY",
                    HttpStatus.INTERNAL_SERVER_ERROR);
        }
        if (e.getStatusCode() == HttpStatus.TOO_MANY_REQUESTS) {
            return new EventException(
                    "Ticketmaster rate limit exceeded — please try again later",
                    HttpStatus.SERVICE_UNAVAILABLE);
        }
        return new EventException("Event search unavailable: " + e.getStatusCode(),
                HttpStatus.BAD_GATEWAY);
    }
}
