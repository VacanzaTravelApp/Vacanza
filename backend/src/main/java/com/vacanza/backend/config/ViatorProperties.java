package com.vacanza.backend.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

/**
 * Configuration properties for the Viator Partner API.
 *
 * Binds to the "viator" prefix in application.yaml:
 *   viator:
 *     base-url: https://api.sandbox.viator.com/partner
 *     api-key: ${VIATOR_API_KEY}
 *     connect-timeout: 10s
 *     read-timeout: 30s
 *     cache-ttl-minutes: 60
 */
@Getter
@Setter
@ConfigurationProperties(prefix = "viator")
public class ViatorProperties {

    /**
     * Viator Partner API base URL.
     * Sandbox: https://api.sandbox.viator.com/partner
     * Production: https://api.viator.com/partner
     */
    private String baseUrl = "https://api.sandbox.viator.com/partner";

    /**
     * Viator experience API key (exp-api-key header).
     */
    private String apiKey;

    /**
     * Connection timeout for Viator requests.
     */
    private Duration connectTimeout = Duration.ofSeconds(10);

    /**
     * Read timeout for Viator requests.
     */
    private Duration readTimeout = Duration.ofSeconds(30);

    /**
     * TTL in minutes for the in-memory Caffeine cache (attraction → price).
     */
    private int cacheTtlMinutes = 60;
}
