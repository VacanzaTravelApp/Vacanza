package com.vacanza.backend.integration.viator;

import com.vacanza.backend.config.ViatorProperties;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.util.List;
import java.util.Map;

/**
 * Viator Partner API client.
 * <p>
 * Free-text attraction search is implemented with {@code POST /search/freetext} and
 * {@code searchType ATTRACTIONS}. The {@code POST /attractions/search} endpoint lists attractions
 * for a fixed {@code destinationId} and does not accept a general search string such as
 * "Hagia Sophia"; see Partner API technical guide.
 */
@Slf4j
@Component
public class ViatorClient {

    private static final String PATH_FREETEXT = "/search/freetext";
    private static final String PATH_PRODUCTS_SEARCH = "/products/search";

    private final WebClient webClient;
    private final ViatorProperties viatorProperties;

    public ViatorClient(
            @Qualifier("viatorWebClient") WebClient webClient,
            ViatorProperties viatorProperties) {
        this.webClient = webClient;
        this.viatorProperties = viatorProperties;
    }

    /**
     * Search attractions by free-text term and language.
     * Uses {@code POST /search/freetext} (see class Javadoc).
     */
    public ViatorAttractionSearchResponse searchAttractions(String searchTerm, String language) {
        if (!StringUtils.hasText(viatorProperties.getApiKey())) {
            log.debug("[VIATOR] searchAttractions skipped — no API key");
            return ViatorAttractionSearchResponse.empty();
        }
        if (!StringUtils.hasText(searchTerm)) {
            return ViatorAttractionSearchResponse.empty();
        }
        try {
            Map<String, Object> body = Map.of(
                    "searchTerm", searchTerm.trim(),
                    "searchTypes", List.of(Map.of(
                            "searchType", "ATTRACTIONS",
                            "pagination", Map.of("start", 1, "count", 30))),
                    "currency", "USD");
            ViatorAttractionSearchResponse.ViatorFreetextSearchWire wire = webClient.post()
                    .uri(PATH_FREETEXT)
                    .header(HttpHeaders.ACCEPT_LANGUAGE, acceptLanguage(language))
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(ViatorAttractionSearchResponse.ViatorFreetextSearchWire.class)
                    .block();
            return ViatorAttractionSearchResponse.fromFreetextWire(wire);
        } catch (WebClientResponseException e) {
            return handleWebClientExceptionForAttractions(e);
        } catch (Exception e) {
            log.warn("[VIATOR] searchAttractions failed: {}", e.getMessage());
            return ViatorAttractionSearchResponse.empty();
        }
    }

    /**
     * Search products for an attraction and currency.
     * {@code POST /products/search} with {@code filtering.attractionId}.
     */
    public ViatorProductSearchResponse searchProducts(long attractionId, String currency) {
        if (!StringUtils.hasText(viatorProperties.getApiKey())) {
            log.debug("[VIATOR] searchProducts skipped — no API key");
            return ViatorProductSearchResponse.empty();
        }
        String ccy = StringUtils.hasText(currency) ? currency.trim().toUpperCase() : "USD";
        try {
            Map<String, Object> body = Map.of(
                    "filtering", Map.of("attractionId", attractionId),
                    "currency", ccy,
                    "pagination", Map.of("start", 1, "count", 50));
            ViatorProductSearchResponse response = webClient.post()
                    .uri(PATH_PRODUCTS_SEARCH)
                    .header(HttpHeaders.ACCEPT_LANGUAGE, "en-US")
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(ViatorProductSearchResponse.class)
                    .block();
            return response != null ? response : ViatorProductSearchResponse.empty();
        } catch (WebClientResponseException e) {
            return handleWebClientExceptionForProducts(e);
        } catch (Exception e) {
            log.warn("[VIATOR] searchProducts failed: {}", e.getMessage());
            return ViatorProductSearchResponse.empty();
        }
    }

    private ViatorAttractionSearchResponse handleWebClientExceptionForAttractions(WebClientResponseException e) {
        int code = e.getStatusCode().value();
        if (shouldLogAndReturnEmpty(code)) {
            log.warn("[VIATOR] searchAttractions HTTP {} — returning empty results. {}",
                    code, shortBody(e));
            return ViatorAttractionSearchResponse.empty();
        }
        log.warn("[VIATOR] searchAttractions HTTP {} — {}", code, shortBody(e));
        return ViatorAttractionSearchResponse.empty();
    }

    private ViatorProductSearchResponse handleWebClientExceptionForProducts(WebClientResponseException e) {
        int code = e.getStatusCode().value();
        if (shouldLogAndReturnEmpty(code)) {
            log.warn("[VIATOR] searchProducts HTTP {} — returning empty results. {}",
                    code, shortBody(e));
            return ViatorProductSearchResponse.empty();
        }
        log.warn("[VIATOR] searchProducts HTTP {} — {}", code, shortBody(e));
        return ViatorProductSearchResponse.empty();
    }

    /**
     * Task: 404, 429, 5xx — log and empty. Also treat 401/403 as empty so invalid or pending keys do not break callers.
     */
    private static boolean shouldLogAndReturnEmpty(int code) {
        return code == 401 || code == 403 || code == 404 || code == 429 || code >= 500;
    }

    private static String shortBody(WebClientResponseException e) {
        String b = e.getResponseBodyAsString();
        if (b == null || b.isEmpty()) {
            return "(no body)";
        }
        return b.length() > 280 ? b.substring(0, 280) + "…" : b;
    }

    private static String acceptLanguage(String language) {
        if (!StringUtils.hasText(language)) {
            return "en-US";
        }
        String t = language.trim();
        if (t.length() == 2) {
            return t.toLowerCase() + "-US";
        }
        return t;
    }
}
