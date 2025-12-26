package com.vacanza.backend.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Getter
@Setter
@ConfigurationProperties(prefix = "foursquare")
public class FoursquareProperties {
    private String baseUrl;
    private String apiKey;
}