package com.vacanza.backend.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

@Getter
@Setter
@ConfigurationProperties(prefix = "amadeus")
public class AmadeusProperties {

    /**
     * Amadeus Self-Service API base URL.
     * Test: https://test.api.amadeus.com
     * Prod: https://api.amadeus.com
     */
    private String baseUrl = "https://test.api.amadeus.com";

    /**
     * OAuth2 client ID (API Key from Amadeus portal).
     */
    private String clientId;

    /**
     * OAuth2 client secret (API Secret from Amadeus portal).
     */
    private String clientSecret;

    /**
     * Connection timeout when connecting to Amadeus API.
     */
    private Duration connectTimeout = Duration.ofSeconds(10);

    /**
     * Read timeout when waiting for Amadeus API response.
     */
    private Duration readTimeout = Duration.ofSeconds(30);
}
