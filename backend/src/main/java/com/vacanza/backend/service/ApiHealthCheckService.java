package com.vacanza.backend.service;

import com.vacanza.backend.config.*;
import com.vacanza.backend.dto.response.HealthCheckResultDTO;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Performs on-demand health checks against external APIs.
 * Each check sends a minimal, lightweight request to verify the API is reachable.
 *
 * Supported services: foursquare, mapbox, serpapi, ticketmaster,
 *                     openmeteo, frankfurter, viator, ai
 */
@Slf4j
@Service
public class ApiHealthCheckService {

    private final WebClient foursquareWebClient;
    private final WebClient mapboxWebClient;
    private final WebClient aiWebClient;
    private final WebClient serpApiWebClient;
    private final WebClient ticketmasterWebClient;
    private final WebClient openMeteoWebClient;
    private final WebClient frankfurterWebClient;
    private final WebClient viatorWebClient;

    private final SerpApiProperties serpApiProperties;
    private final TicketmasterProperties ticketmasterProperties;
    private final ViatorProperties viatorProperties;

    private static final Set<String> SUPPORTED_SERVICES = Set.of(
            "foursquare", "mapbox", "ai", "serpapi",
            "ticketmaster", "openmeteo", "frankfurter", "viator"
    );

    public ApiHealthCheckService(
            @Qualifier("foursquareWebClient") WebClient foursquareWebClient,
            @Qualifier("mapboxGeocodingWebClient") WebClient mapboxWebClient,
            @Qualifier("aiWebClient") WebClient aiWebClient,
            @Qualifier("serpApiWebClient") WebClient serpApiWebClient,
            @Qualifier("ticketmasterWebClient") WebClient ticketmasterWebClient,
            @Qualifier("openMeteoWebClient") WebClient openMeteoWebClient,
            @Qualifier("frankfurterWebClient") WebClient frankfurterWebClient,
            @Qualifier("viatorWebClient") WebClient viatorWebClient,
            SerpApiProperties serpApiProperties,
            TicketmasterProperties ticketmasterProperties,
            ViatorProperties viatorProperties) {
        this.foursquareWebClient = foursquareWebClient;
        this.mapboxWebClient = mapboxWebClient;
        this.aiWebClient = aiWebClient;
        this.serpApiWebClient = serpApiWebClient;
        this.ticketmasterWebClient = ticketmasterWebClient;
        this.openMeteoWebClient = openMeteoWebClient;
        this.frankfurterWebClient = frankfurterWebClient;
        this.viatorWebClient = viatorWebClient;
        this.serpApiProperties = serpApiProperties;
        this.ticketmasterProperties = ticketmasterProperties;
        this.viatorProperties = viatorProperties;
    }

    public Set<String> getSupportedServices() {
        return SUPPORTED_SERVICES;
    }

    /**
     * Perform a health check for the given service.
     *
     * @param serviceName lowercase service identifier (e.g. "frankfurter")
     * @return health check result with status, response time, and message
     * @throws IllegalArgumentException if the service name is not recognized
     */
    public HealthCheckResultDTO check(String serviceName) {
        String key = serviceName.toLowerCase().trim();
        if (!SUPPORTED_SERVICES.contains(key)) {
            throw new IllegalArgumentException("Unknown service: " + serviceName
                    + ". Supported: " + SUPPORTED_SERVICES);
        }

        long start = System.currentTimeMillis();
        try {
            String displayName = performCheck(key);
            long elapsed = System.currentTimeMillis() - start;
            log.info("[HEALTH-CHECK] {} -> UP ({}ms)", key, elapsed);
            return HealthCheckResultDTO.builder()
                    .serviceName(displayName)
                    .status("UP")
                    .responseMs(elapsed)
                    .message("OK")
                    .checkedAt(Instant.now().toString())
                    .build();
        } catch (Exception e) {
            long elapsed = System.currentTimeMillis() - start;
            String errorMsg = e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName();
            log.warn("[HEALTH-CHECK] {} -> DOWN ({}ms): {}", key, elapsed, errorMsg);
            return HealthCheckResultDTO.builder()
                    .serviceName(getDisplayName(key))
                    .status("DOWN")
                    .responseMs(elapsed)
                    .message(errorMsg)
                    .checkedAt(Instant.now().toString())
                    .build();
        }
    }

    /**
     * Executes the lightest possible request for each API.
     * Returns the display name on success; throws on failure.
     */
    private String performCheck(String key) {
        return switch (key) {
            case "frankfurter" -> {
                // GET /v1/currencies — returns currency list, no computation
                frankfurterWebClient.get()
                        .uri("/v1/currencies")
                        .retrieve()
                        .bodyToMono(String.class)
                        .block();
                yield "Currency Exchange (Frankfurter)";
            }
            case "openmeteo" -> {
                // GET /forecast — minimal 1-day forecast at coordinates 0,0
                openMeteoWebClient.get()
                        .uri(uriBuilder -> uriBuilder
                                .path("/forecast")
                                .queryParam("latitude", 41.01)
                                .queryParam("longitude", 28.98)
                                .queryParam("forecast_days", 1)
                                .queryParam("daily", "weathercode")
                                .queryParam("timezone", "auto")
                                .build())
                        .retrieve()
                        .bodyToMono(String.class)
                        .block();
                yield "Weather Service (OpenMeteo)";
            }
            case "foursquare" -> {
                // GET /places/search — single place lookup
                foursquareWebClient.get()
                        .uri(uriBuilder -> uriBuilder
                                .path("/places/search")
                                .queryParam("query", "test")
                                .queryParam("limit", 1)
                                .build())
                        .retrieve()
                        .bodyToMono(String.class)
                        .block();
                yield "Local Places (Foursquare)";
            }
            case "mapbox" -> {
                // GET /search/searchbox/v1/forward — single geocode lookup
                mapboxWebClient.get()
                        .uri(uriBuilder -> uriBuilder
                                .path("/search/searchbox/v1/forward")
                                .queryParam("q", "Istanbul")
                                .queryParam("limit", 1)
                                .queryParam("language", "en")
                                .build())
                        .retrieve()
                        .bodyToMono(String.class)
                        .block();
                yield "Maps & Geocoding (Mapbox)";
            }
            case "serpapi" -> {
                // GET /search.json — minimal search with API key
                serpApiWebClient.get()
                        .uri(uriBuilder -> uriBuilder
                                .path("/search.json")
                                .queryParam("engine", "google")
                                .queryParam("q", "ping")
                                .queryParam("num", 1)
                                .queryParam("api_key", serpApiProperties.getApiKey())
                                .build())
                        .retrieve()
                        .bodyToMono(String.class)
                        .block();
                yield "Hotel & Flight Search (SerpApi)";
            }
            case "ticketmaster" -> {
                // GET /events.json — single event lookup with API key
                ticketmasterWebClient.get()
                        .uri(uriBuilder -> uriBuilder
                                .path("/events.json")
                                .queryParam("size", 1)
                                .queryParam("apikey", ticketmasterProperties.getApiKey())
                                .build())
                        .retrieve()
                        .bodyToMono(String.class)
                        .block();
                yield "Events (Ticketmaster)";
            }
            case "viator" -> {
                // POST /search/freetext — minimal product search
                if (!StringUtils.hasText(viatorProperties.getApiKey())) {
                    throw new IllegalStateException("Viator API key not configured");
                }
                viatorWebClient.post()
                        .uri("/search/freetext")
                        .contentType(MediaType.APPLICATION_JSON)
                        .bodyValue(Map.of(
                                "searchTerm", "test",
                                "searchTypes", List.of(Map.of(
                                        "searchType", "PRODUCTS",
                                        "pagination", Map.of("start", 1, "count", 1))),
                                "currency", "USD"))
                        .retrieve()
                        .bodyToMono(String.class)
                        .block();
                yield "Tours/Activities (Viator)";
            }
            case "ai" -> {
                // GET /health or a lightweight endpoint on the AI service
                // Try /health first, fall back to listing conversations
                aiWebClient.get()
                        .uri("/health")
                        .retrieve()
                        .bodyToMono(String.class)
                        .block();
                yield "AI Recommendation Engine";
            }
            default -> throw new IllegalArgumentException("Unknown service: " + key);
        };
    }

    private String getDisplayName(String key) {
        return switch (key) {
            case "frankfurter" -> "Currency Exchange (Frankfurter)";
            case "openmeteo" -> "Weather Service (OpenMeteo)";
            case "foursquare" -> "Local Places (Foursquare)";
            case "mapbox" -> "Maps & Geocoding (Mapbox)";
            case "serpapi" -> "Hotel & Flight Search (SerpApi)";
            case "ticketmaster" -> "Events (Ticketmaster)";
            case "viator" -> "Tours/Activities (Viator)";
            case "ai" -> "AI Recommendation Engine";
            default -> key;
        };
    }
}
