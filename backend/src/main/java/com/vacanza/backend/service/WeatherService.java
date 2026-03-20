package com.vacanza.backend.service;

import com.vacanza.backend.config.OpenMeteoProperties;
import com.vacanza.backend.dto.weather.DailyWeatherSummary;
import com.vacanza.backend.integration.OpenMeteoClient;
import com.vacanza.backend.integration.OpenMeteoForecastResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Maps Open-Meteo forecast to internal daily summaries. Failures yield an empty list.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class WeatherService {

    private final OpenMeteoClient openMeteoClient;
    private final OpenMeteoProperties openMeteoProperties;

    /**
     * Daily forecast at coordinates. Never throws; returns empty list if the API fails or data is unusable.
     */
    public List<DailyWeatherSummary> getDailyForecast(double latitude, double longitude, int forecastDays) {
        try {
            Duration blockTimeout = openMeteoProperties.getReadTimeout().plusSeconds(2);
            List<DailyWeatherSummary> out = openMeteoClient
                    .getForecast(latitude, longitude, forecastDays)
                    .map(this::mapToDailySummaries)
                    .defaultIfEmpty(Collections.emptyList())
                    .block(blockTimeout);
            return out != null ? out : Collections.emptyList();
        } catch (Exception e) {
            log.warn("Weather forecast unavailable lat={}, lon={}: {}", latitude, longitude, e.getMessage());
            return Collections.emptyList();
        }
    }

    private List<DailyWeatherSummary> mapToDailySummaries(OpenMeteoForecastResponse resp) {
        if (resp == null || resp.getDaily() == null) {
            return Collections.emptyList();
        }
        OpenMeteoForecastResponse.Daily d = resp.getDaily();
        List<String> times = d.getTime();
        if (times == null || times.isEmpty()) {
            return Collections.emptyList();
        }

        List<Integer> codes = d.getWeathercode();
        List<Double> tMax = d.getTemperature2mMax();
        List<Double> tMin = d.getTemperature2mMin();
        List<Double> precip = d.getPrecipitationProbabilityMax();

        List<DailyWeatherSummary> rows = new ArrayList<>(times.size());
        for (int i = 0; i < times.size(); i++) {
            LocalDate date = parseDate(times.get(i));
            if (date == null) {
                continue;
            }
            rows.add(new DailyWeatherSummary(
                    date,
                    intAt(codes, i),
                    doubleAt(tMax, i),
                    doubleAt(tMin, i),
                    doubleAt(precip, i)));
        }
        return rows;
    }

    private static LocalDate parseDate(String iso) {
        if (iso == null || iso.isBlank()) {
            return null;
        }
        try {
            return LocalDate.parse(iso.length() >= 10 ? iso.substring(0, 10) : iso);
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    private static Integer intAt(List<Integer> list, int i) {
        if (list == null || i < 0 || i >= list.size()) {
            return null;
        }
        return list.get(i);
    }

    private static Double doubleAt(List<Double> list, int i) {
        if (list == null || i < 0 || i >= list.size()) {
            return null;
        }
        return list.get(i);
    }
}
