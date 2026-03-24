package com.vacanza.backend.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

@Getter
@Setter
@ConfigurationProperties(prefix = "foursquare")
public class FoursquareProperties {

    private String baseUrl = "https://api.foursquare.com/v3";

    /** Foursquare Places API key (Bearer token). */
    private String apiKey;

    private Duration connectTimeout = Duration.ofSeconds(8);
    private Duration readTimeout = Duration.ofSeconds(15);
}
