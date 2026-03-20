package com.vacanza.backend.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

@Getter
@Setter
@ConfigurationProperties(prefix = "ai-service")
public class AiServiceProperties {

    /**
     * AI service base URL (e.g. http://localhost:8000)
     */
    private String baseUrl = "http://localhost:8000";

    /**
     * Connection timeout when connecting to AI service.
     */
    private Duration connectTimeout = Duration.ofSeconds(10);

    /**
     * Read timeout when waiting for AI service response.
     */
    private Duration readTimeout = Duration.ofSeconds(30);
}
