package com.vacanza.backend.dto.weather;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.LocalDate;

/**
 * One day of forecast, independent of Open-Meteo JSON shape.
 */
public record DailyWeatherSummary(
        @JsonProperty("date") LocalDate date,
        @JsonProperty("weather_code") Integer weatherCode,
        @JsonProperty("temp_max_celsius") Double tempMaxCelsius,
        @JsonProperty("temp_min_celsius") Double tempMinCelsius,
        @JsonProperty("precipitation_probability_max_percent") Double precipitationProbabilityMaxPercent
) {}
