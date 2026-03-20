package com.vacanza.backend.dto.weather;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.LocalDate;

/**
 * Per-day summary: three sightseeing windows with worst-case code and max precip in each window.
 */
public record DayPartWeatherDay(
        @JsonProperty("date") LocalDate date,
        @JsonProperty("morning") DayPartSlot morning,
        @JsonProperty("afternoon") DayPartSlot afternoon,
        @JsonProperty("evening") DayPartSlot evening
) {}
