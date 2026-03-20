package com.vacanza.backend.dto.weather;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

/**
 * Single Open-Meteo fetch: daily rows for UI plus day-part rows for itinerary planning.
 */
public record WeatherPlanningForecast(
        @JsonProperty("daily") List<DailyWeatherSummary> daily,
        @JsonProperty("day_parts") List<DayPartWeatherDay> dayParts
) {}
