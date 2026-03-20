package com.vacanza.backend.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

/**
 * Open-Meteo API (no API key; see https://open-meteo.com/ ).
 * Forecast requests use {@code GET /v1/forecast} under {@link #baseUrl}.
 */
@Getter
@Setter
@ConfigurationProperties(prefix = "open-meteo")
public class OpenMeteoProperties {

    /**
     * API root including version segment, e.g. {@code https://api.open-meteo.com/v1}
     */
    private String baseUrl = "https://api.open-meteo.com/v1";

    private Duration connectTimeout = Duration.ofSeconds(10);

    private Duration readTimeout = Duration.ofSeconds(30);
}
