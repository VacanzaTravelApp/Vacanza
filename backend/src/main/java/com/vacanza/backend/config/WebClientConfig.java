package com.vacanza.backend.config;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.web.reactive.function.client.WebClient;

@Configuration
@EnableConfigurationProperties(FoursquareProperties.class)
public class WebClientConfig {

    @Bean
    public WebClient foursquareWebClient(FoursquareProperties props) {
        return WebClient.builder()
                .baseUrl(props.getBaseUrl())
                .defaultHeader(HttpHeaders.AUTHORIZATION, props.getApiKey())
                .defaultHeader(HttpHeaders.ACCEPT, "application/json")
                .build();
    }
}