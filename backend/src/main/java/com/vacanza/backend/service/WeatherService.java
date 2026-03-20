package com.vacanza.backend.service;

import com.vacanza.backend.config.OpenMeteoProperties;
import com.vacanza.backend.dto.weather.DailyWeatherSummary;
import com.vacanza.backend.dto.weather.DayPartSlot;
import com.vacanza.backend.dto.weather.DayPartWeatherDay;
import com.vacanza.backend.dto.weather.WeatherPlanningForecast;
import com.vacanza.backend.integration.OpenMeteoClient;
import com.vacanza.backend.integration.OpenMeteoForecastResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.TreeSet;

/**
 * Maps Open-Meteo forecast to daily summaries and to morning/afternoon/evening day-part summaries.
 * Failures yield empty lists.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class WeatherService {

    private static final int MIN_DAYS = 1;
    private static final int MAX_DAYS = 16;

    /** Local hours [start, end) for each sightseeing window. */
    private static final int MORNING_START = 8;
    private static final int MORNING_END = 12;
    private static final int AFTERNOON_START = 12;
    private static final int AFTERNOON_END = 17;
    private static final int EVENING_START = 17;
    private static final int EVENING_END = 21;

    private final OpenMeteoClient openMeteoClient;
    private final OpenMeteoProperties openMeteoProperties;

    /**
     * Daily forecast at coordinates. Never throws; returns empty list if the API fails or data is unusable.
     * Uses the same Open-Meteo request as {@link #getPlanningForecast}.
     */
    public List<DailyWeatherSummary> getDailyForecast(double latitude, double longitude, int forecastDays) {
        return getPlanningForecast(latitude, longitude, forecastDays).daily();
    }

    /**
     * Single fetch: daily rows (UI) + hourly-derived day parts (itinerary planning).
     */
    public WeatherPlanningForecast getPlanningForecast(double latitude, double longitude, int tripDays) {
        int days = clampForecastDays(tripDays);
        try {
            Duration blockTimeout = openMeteoProperties.getReadTimeout().plusSeconds(2);
            OpenMeteoForecastResponse resp = openMeteoClient
                    .getForecast(latitude, longitude, days)
                    .block(blockTimeout);
            if (resp == null) {
                return new WeatherPlanningForecast(Collections.emptyList(), Collections.emptyList());
            }
            return new WeatherPlanningForecast(
                    mapToDailySummaries(resp),
                    mapToDayPartSummaries(resp, days));
        } catch (Exception e) {
            log.warn("Weather forecast unavailable lat={}, lon={}: {}", latitude, longitude, e.getMessage());
            return new WeatherPlanningForecast(Collections.emptyList(), Collections.emptyList());
        }
    }

    /**
     * Day-part rows only (same fetch cost as {@link #getPlanningForecast} — prefer that if you also need daily).
     */
    public List<DayPartWeatherDay> getDayPartSummaries(double latitude, double longitude, int tripDays) {
        return getPlanningForecast(latitude, longitude, tripDays).dayParts();
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

    private List<DayPartWeatherDay> mapToDayPartSummaries(OpenMeteoForecastResponse resp, int tripDays) {
        if (resp == null || resp.getHourly() == null) {
            return Collections.emptyList();
        }
        OpenMeteoForecastResponse.Hourly h = resp.getHourly();
        List<String> times = h.getTime();
        if (times == null || times.isEmpty()) {
            return Collections.emptyList();
        }
        List<Integer> codes = h.getWeathercode();
        List<Integer> precips = h.getPrecipitationProbability();
        int n = times.size();

        TreeSet<LocalDate> distinctDates = new TreeSet<>();
        for (int i = 0; i < n; i++) {
            LocalDateTime ldt = parseHourlyDateTime(times.get(i));
            if (ldt != null) {
                distinctDates.add(ldt.toLocalDate());
            }
        }
        if (distinctDates.isEmpty()) {
            return Collections.emptyList();
        }

        int limit = Math.min(Math.max(tripDays, MIN_DAYS), MAX_DAYS);
        List<LocalDate> selectedDays = distinctDates.stream().limit(limit).toList();

        List<DayPartWeatherDay> out = new ArrayList<>(selectedDays.size());
        for (LocalDate date : selectedDays) {
            List<HourPoint> hours = new ArrayList<>();
            for (int i = 0; i < n; i++) {
                LocalDateTime ldt = parseHourlyDateTime(times.get(i));
                if (ldt == null || !ldt.toLocalDate().equals(date)) {
                    continue;
                }
                hours.add(new HourPoint(
                        ldt.getHour(),
                        intAt(codes, i),
                        intAt(precips, i)));
            }
            DayPartSlot morning = aggregateSlot(hours, MORNING_START, MORNING_END);
            DayPartSlot afternoon = aggregateSlot(hours, AFTERNOON_START, AFTERNOON_END);
            DayPartSlot evening = aggregateSlot(hours, EVENING_START, EVENING_END);
            out.add(new DayPartWeatherDay(date, morning, afternoon, evening));
        }
        return out;
    }

    private static DayPartSlot aggregateSlot(List<HourPoint> hourPoints, int minInc, int maxExc) {
        List<HourPoint> slice = hourPoints.stream()
                .filter(hp -> hp.hour >= minInc && hp.hour < maxExc)
                .toList();
        if (slice.isEmpty()) {
            return null;
        }
        int maxPrecip = slice.stream()
                .map(HourPoint::precip)
                .filter(Objects::nonNull)
                .mapToInt(Integer::intValue)
                .max()
                .orElse(0);
        boolean anyPrecip = slice.stream().anyMatch(hp -> hp.precip != null);
        Integer code = pickRepresentativeCode(slice, maxPrecip, anyPrecip);
        boolean avoid = shouldAvoidOutdoor(slice, maxPrecip, code);
        return new DayPartSlot(code, anyPrecip ? maxPrecip : null, avoid);
    }

    /**
     * Prefer weather code from hour(s) with maximum precip; otherwise worst numeric code in slice (heuristic).
     */
    private static Integer pickRepresentativeCode(List<HourPoint> slice, int maxPrecip, boolean anyPrecip) {
        if (anyPrecip) {
            List<HourPoint> tier = slice.stream()
                    .filter(hp -> hp.precip != null && hp.precip == maxPrecip)
                    .toList();
            Integer fromTier = tier.stream()
                    .map(HourPoint::code)
                    .filter(Objects::nonNull)
                    .max(Comparator.naturalOrder())
                    .orElse(null);
            if (fromTier != null) {
                return fromTier;
            }
        }
        return slice.stream()
                .map(HourPoint::code)
                .filter(Objects::nonNull)
                .max(Comparator.naturalOrder())
                .orElse(null);
    }

    private static boolean shouldAvoidOutdoor(List<HourPoint> slice, int maxPrecip, Integer representativeCode) {
        if (maxPrecip >= 60) {
            return true;
        }
        if (representativeCode != null && isBadOutdoorCode(representativeCode)) {
            return true;
        }
        return slice.stream()
                .map(HourPoint::code)
                .filter(Objects::nonNull)
                .anyMatch(WeatherService::isBadOutdoorCode);
    }

    /** WMO: rain/drizzle, snow, showers, thunderstorms — defer extended outdoor plans. */
    private static boolean isBadOutdoorCode(int code) {
        if (code >= 51 && code <= 67) {
            return true;
        }
        if (code >= 71 && code <= 77) {
            return true;
        }
        if (code >= 80 && code <= 99) {
            return true;
        }
        return false;
    }

    private record HourPoint(int hour, Integer code, Integer precip) {}

    private static LocalDateTime parseHourlyDateTime(String iso) {
        if (iso == null || iso.isBlank()) {
            return null;
        }
        try {
            return LocalDateTime.parse(iso.length() >= 16 ? iso.substring(0, 16) : iso);
        } catch (DateTimeParseException e) {
            try {
                return LocalDateTime.parse(iso);
            } catch (DateTimeParseException e2) {
                return null;
            }
        }
    }

    private static int clampForecastDays(int forecastDays) {
        return Math.min(Math.max(forecastDays, MIN_DAYS), MAX_DAYS);
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
