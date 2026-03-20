package com.vacanza.backend.integration;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

/**
 * Open-Meteo forecast API — {@code GET /forecast} (base URL includes {@code /v1}).
 */
@Slf4j
@Component
public class OpenMeteoClient {

    /** Open-Meteo allows up to 16 daily steps on the free forecast API. */
    private static final int MIN_DAYS = 1;
    private static final int MAX_DAYS = 16;

    private static final String DAILY_VARS =
            "weathercode,temperature_2m_max,temperature_2m_min,precipitation_probability_max";

    private static final String HOURLY_VARS = "weathercode,precipitation_probability";

    private final WebClient webClient;

    public OpenMeteoClient(@Qualifier("openMeteoWebClient") WebClient webClient) {
        this.webClient = webClient;
    }

    /**
     * Daily and hourly forecast at the given coordinates. Uses {@code timezone=auto} so hourly
     * {@code time} values are in the location's local timezone (see response {@code timezone}).
     *
     * @param latitude  WGS84 latitude
     * @param longitude WGS84 longitude
     * @param forecastDays number of days (clamped 1–16)
     * @return parsed body, or empty if the request fails
     */
    public Mono<OpenMeteoForecastResponse> getForecast(double latitude, double longitude, int forecastDays) {
        int days = Math.min(Math.max(forecastDays, MIN_DAYS), MAX_DAYS);

        return webClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/forecast")
                        .queryParam("latitude", latitude)
                        .queryParam("longitude", longitude)
                        .queryParam("forecast_days", days)
                        .queryParam("timezone", "auto")
                        .queryParam("daily", DAILY_VARS)
                        .queryParam("hourly", HOURLY_VARS)
                        .build())
                .retrieve()
                .bodyToMono(OpenMeteoForecastResponse.class)
                .doOnError(e -> log.warn(
                        "Open-Meteo forecast failed lat={}, lon={}, days={}: {}",
                        latitude, longitude, days, e.toString()))
                .onErrorResume(e -> Mono.empty());
    }
}
