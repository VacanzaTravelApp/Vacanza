package com.vacanza.backend.integration;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.util.List;
import java.util.Map;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class OverpassResponse {

    @JsonProperty("elements")
    private List<Element> elements;

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Element {
        private String type; // node/way/relation
        private Long id;

        // node için
        private Double lat;
        private Double lon;

        // tags: name, amenity, tourism vs.
        private Map<String, String> tags;
    }
}