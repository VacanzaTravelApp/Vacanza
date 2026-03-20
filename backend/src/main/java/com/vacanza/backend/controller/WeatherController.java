package com.vacanza.backend.controller;

import com.vacanza.backend.dto.weather.DailyWeatherSummary;
import com.vacanza.backend.service.WeatherService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Debug / internal: daily forecast via Open-Meteo (same security as other authenticated APIs).
 */
@RestController
@RequestMapping("/api/weather")
@RequiredArgsConstructor
public class WeatherController {

    private final WeatherService weatherService;

    @GetMapping("/forecast")
    public ResponseEntity<List<DailyWeatherSummary>> forecast(
            @RequestParam("lat") double lat,
            @RequestParam("lon") double lon,
            @RequestParam(value = "days", required = false, defaultValue = "7") int days) {
        if (!validLatLon(lat, lon)) {
            return ResponseEntity.badRequest().build();
        }
        return ResponseEntity.ok(weatherService.getDailyForecast(lat, lon, days));
    }

    private static boolean validLatLon(double lat, double lon) {
        return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
    }
}
