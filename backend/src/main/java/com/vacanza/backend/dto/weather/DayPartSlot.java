package com.vacanza.backend.dto.weather;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * One local time window (morning / afternoon / evening) derived from hourly Open-Meteo data.
 */
public record DayPartSlot(
        @JsonProperty("weather_code") Integer weatherCode,
        @JsonProperty("precipitation_probability_max_percent") Integer precipitationProbabilityMaxPercent,
        @JsonProperty("avoid_outdoor") Boolean avoidOutdoor
) {}
