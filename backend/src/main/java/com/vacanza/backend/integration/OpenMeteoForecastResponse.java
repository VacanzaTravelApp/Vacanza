package com.vacanza.backend.integration;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.util.List;

/**
 * Subset of <a href="https://open-meteo.com/en/docs">Open-Meteo</a> forecast JSON (daily variables).
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class OpenMeteoForecastResponse {

    private Double latitude;
    private Double longitude;

    private Daily daily;

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Daily {

        private List<String> time;

        private List<Integer> weathercode;

        @JsonProperty("temperature_2m_max")
        private List<Double> temperature2mMax;

        @JsonProperty("temperature_2m_min")
        private List<Double> temperature2mMin;

        @JsonProperty("precipitation_probability_max")
        private List<Double> precipitationProbabilityMax;
    }
}
