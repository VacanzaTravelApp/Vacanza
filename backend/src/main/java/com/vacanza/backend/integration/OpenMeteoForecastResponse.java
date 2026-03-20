package com.vacanza.backend.integration;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.util.List;

/**
 * Subset of <a href="https://open-meteo.com/en/docs">Open-Meteo</a> forecast JSON (daily + hourly).
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class OpenMeteoForecastResponse {

    private Double latitude;
    private Double longitude;

    /** IANA id when {@code timezone=auto}, e.g. {@code Europe/Istanbul}. */
    private String timezone;

    private Daily daily;

    private Hourly hourly;

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

    /** Hourly steps in local time when {@code timezone=auto} (ISO-8601 strings). */
    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Hourly {

        private List<String> time;

        private List<Integer> weathercode;

        @JsonProperty("precipitation_probability")
        private List<Integer> precipitationProbability;
    }
}
