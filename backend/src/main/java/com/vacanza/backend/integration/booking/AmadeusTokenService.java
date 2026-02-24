package com.vacanza.backend.integration.booking;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.vacanza.backend.config.AmadeusProperties;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.BodyInserters;
import org.springframework.web.reactive.function.client.WebClient;

import java.time.Instant;

/**
 * Manages OAuth2 client_credentials token retrieval and caching
 * for the Amadeus Self-Service API.
 *
 * Token is cached in memory and automatically refreshed
 * when it expires (based on expires_in from the token response).
 */
@Slf4j
@Component
public class AmadeusTokenService {

    private final WebClient webClient;
    private final AmadeusProperties props;

    private String cachedToken;
    private Instant tokenExpiry = Instant.EPOCH;

    public AmadeusTokenService(
            @Qualifier("amadeusWebClient") WebClient webClient,
            AmadeusProperties props) {
        this.webClient = webClient;
        this.props = props;
    }

    /**
     * Returns a valid Bearer token. If the cached token is expired
     * or not yet retrieved, fetches a new one from Amadeus.
     */
    public String getToken() {
        if (isTokenValid()) {
            return cachedToken;
        }
        return refreshToken();
    }

    private boolean isTokenValid() {
        return cachedToken != null && Instant.now().isBefore(tokenExpiry);
    }

    private synchronized String refreshToken() {
        // Double-check after acquiring lock
        if (isTokenValid()) {
            return cachedToken;
        }

        log.info("[AMADEUS] Requesting new OAuth2 token...");

        TokenResponse response = webClient.post()
                .uri("/v1/security/oauth2/token")
                .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                .body(BodyInserters
                        .fromFormData("grant_type", "client_credentials")
                        .with("client_id", props.getClientId())
                        .with("client_secret", props.getClientSecret()))
                .retrieve()
                .bodyToMono(TokenResponse.class)
                .block();

        if (response == null || response.getAccessToken() == null) {
            throw new RuntimeException("Failed to retrieve Amadeus OAuth2 token");
        }

        this.cachedToken = response.getAccessToken();
        // Refresh 60 seconds before actual expiry to avoid edge cases
        this.tokenExpiry = Instant.now().plusSeconds(response.getExpiresIn() - 60);

        log.info("[AMADEUS] Token acquired, expires in {} seconds", response.getExpiresIn());
        return cachedToken;
    }

    @Data
    static class TokenResponse {
        @JsonProperty("access_token")
        private String accessToken;

        @JsonProperty("token_type")
        private String tokenType;

        @JsonProperty("expires_in")
        private long expiresIn;
    }
}
