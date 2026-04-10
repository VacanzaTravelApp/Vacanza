package com.vacanza.backend.integration.viator;

import com.vacanza.backend.config.ViatorProperties;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientRequestException;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeoutException;

/**
 * Viator Partner API client.
 * <p>
 * Product search is implemented with a single {@code POST /search/freetext} call using
 * {@code searchType PRODUCTS}. This avoids the two-step flow (attraction search → product search)
 * and does not require a {@code destination} parameter.
 */
@Slf4j
@Component
public class ViatorClient {

    private static final String PATH_FREETEXT = "/search/freetext";

    private final WebClient webClient;
    private final ViatorProperties viatorProperties;

    public ViatorClient(
            @Qualifier("viatorWebClient") WebClient webClient,
            ViatorProperties viatorProperties) {
        this.webClient = webClient;
        this.viatorProperties = viatorProperties;
    }

    /**
     * Search products by free-text name (e.g. "Hagia Sophia") using
     * {@code POST /search/freetext} with {@code searchType=PRODUCTS}.
     */
    public ViatorProductSearchResponse searchProductsByName(String searchTerm, String currency) {
        if (!StringUtils.hasText(viatorProperties.getApiKey())) {
            log.debug("[VIATOR] searchProductsByName skipped — no API key");
            return ViatorProductSearchResponse.empty();
        }
        if (!StringUtils.hasText(searchTerm)) {
            return ViatorProductSearchResponse.empty();
        }
        String ccy = StringUtils.hasText(currency) ? currency.trim().toUpperCase() : "USD";
        try {
            Map<String, Object> body = Map.of(
                    "searchTerm", searchTerm.trim(),
                    "searchTypes", List.of(Map.of(
                            "searchType", "PRODUCTS",
                            "pagination", Map.of("start", 1, "count", 10))),
                    "currency", ccy);
            ViatorProductSearchResponse.FreetextWire wire = webClient.post()
                    .uri(PATH_FREETEXT)
                    .header(HttpHeaders.ACCEPT_LANGUAGE, "en-US")
                    .bodyValue(body)
                    .retrieve()
                    .bodyToMono(ViatorProductSearchResponse.FreetextWire.class)
                    .block();
            return ViatorProductSearchResponse.fromFreetextWire(wire);
        } catch (WebClientResponseException e) {
            int code = e.getStatusCode().value();
            log.warn("[VIATOR] searchProductsByName HTTP {} — {}", code, shortBody(e));
            return ViatorProductSearchResponse.empty();
        } catch (Exception e) {
            if (isPartnerTransportFailure(e)) {
                log.warn("[VIATOR] searchProductsByName transport failure: {}", e.toString());
                throw new ViatorPartnerUnavailableException("Viator Partner API unreachable", e);
            }
            log.warn("[VIATOR] searchProductsByName failed: {}", e.getMessage());
            return ViatorProductSearchResponse.empty();
        }
    }

    /**
     * True for network / timeout / connection issues (not HTTP status responses).
     */
    static boolean isPartnerTransportFailure(Throwable t) {
        Throwable c = t;
        while (c != null) {
            if (c instanceof WebClientRequestException) {
                return true;
            }
            if (c instanceof IOException) {
                return true;
            }
            if (c instanceof TimeoutException) {
                return true;
            }
            String name = c.getClass().getName();
            if (name.contains("ConnectException")
                    || name.contains("UnknownHostException")
                    || name.contains("DnsNameResolverTimeout")
                    || (name.contains("Timeout") && name.contains("Exception"))) {
                return true;
            }
            c = c.getCause();
        }
        return false;
    }

    private static String shortBody(WebClientResponseException e) {
        String b = e.getResponseBodyAsString();
        if (b == null || b.isEmpty()) {
            return "(no body)";
        }
        return b.length() > 280 ? b.substring(0, 280) + "…" : b;
    }
}
