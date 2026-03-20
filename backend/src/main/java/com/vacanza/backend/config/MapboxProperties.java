package com.vacanza.backend.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Getter
@Setter
@ConfigurationProperties(prefix = "mapbox")
public class MapboxProperties {

    /**
     * Mapbox public access token (pk.xxx)
     */
    private String accessToken;
}
