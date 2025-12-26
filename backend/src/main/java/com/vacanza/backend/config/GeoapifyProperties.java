package com.vacanza.backend.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Getter
@Setter
@ConfigurationProperties(prefix = "geoapify")
public class GeoapifyProperties {
    private String baseUrl = "https://api.geoapify.com/v2";
    private String apiKey;
}
