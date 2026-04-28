package com.vacanza.backend.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

/**
 * Configuration properties for the Ticketmaster Discovery API.
 *
 * Binds to the "ticketmaster" prefix in application.yaml:
 *   ticketmaster:
 *     base-url: https://app.ticketmaster.com/discovery/v2
 *     api-key: ${TICKETMASTER_API_KEY}
 *     connect-timeout: 10s
 *     read-timeout: 30s
 */
@Getter
@Setter
@ConfigurationProperties(prefix = "ticketmaster")
public class TicketmasterProperties {

    /**
     * Ticketmaster Discovery API base URL (US/global).
     */
    private String baseUrl = "https://app.ticketmaster.com/discovery/v2";

    /**
     * Ticketmaster International Discovery API base URL (European markets).
     */
    private String euBaseUrl = "https://app.ticketmaster.eu/mfxapi/v2";

    /**
     * Ticketmaster API key (Consumer Key from developer.ticketmaster.com).
     */
    private String apiKey;

    /**
     * Connection timeout for Ticketmaster requests.
     */
    private Duration connectTimeout = Duration.ofSeconds(10);

    /**
     * Read timeout for Ticketmaster requests.
     */
    private Duration readTimeout = Duration.ofSeconds(30);
}
