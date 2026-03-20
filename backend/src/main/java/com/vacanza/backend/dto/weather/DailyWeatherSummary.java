package com.vacanza.backend.dto.weather;

import java.time.LocalDate;

/**
 * One day of forecast, independent of Open-Meteo JSON shape.
 */
public record DailyWeatherSummary(
        LocalDate date,
        Integer weatherCode,
        Double tempMaxCelsius,
        Double tempMinCelsius,
        Double precipitationProbabilityMaxPercent
) {}
