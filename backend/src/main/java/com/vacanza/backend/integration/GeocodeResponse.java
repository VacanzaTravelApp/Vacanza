package com.vacanza.backend.integration;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class GeocodeResponse {

    private List<GeocodeResult> results;

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class GeocodeResult {
        private double lat;
        private double lon;
        private String formatted;
        private String city;
        private String country;
    }
}
