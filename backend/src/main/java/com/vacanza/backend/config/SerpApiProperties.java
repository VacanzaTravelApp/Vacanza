package com.vacanza.backend.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

@Getter
@Setter
@ConfigurationProperties(prefix = "serpapi")
public class SerpApiProperties {

    /**
     * SerpApi base URL.
     */
    private String baseUrl = "https://serpapi.com";

    /**
     * SerpApi API key (from serpapi.com dashboard).
     */
    private String apiKey;

    /**
     * Connection timeout for SerpApi requests.
     */
    private Duration connectTimeout = Duration.ofSeconds(10);

    /**
     * Read timeout for SerpApi requests.
     */
    private Duration readTimeout = Duration.ofSeconds(30);
}
