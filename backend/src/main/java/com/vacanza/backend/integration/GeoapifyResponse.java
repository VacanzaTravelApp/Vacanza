package com.vacanza.backend.integration;

import lombok.Data;

import java.util.List;

@Data
public class GeoapifyResponse {
    private List<Feature> features;

    @Data
    public static class Feature {
        private Properties properties;
        private Geometry geometry;
    }

    @Data
    public static class Properties {
        private String name;
        private String category;
        private Double rating;
        private String place_id;
        private String price_level;
    }

    @Data
    public static class Geometry {
        private List<Double> coordinates; // [lng, lat]
    }
}
