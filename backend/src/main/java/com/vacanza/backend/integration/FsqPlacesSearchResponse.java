package com.vacanza.backend.integration;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.util.List;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class FsqPlacesSearchResponse {

    @JsonProperty("results")
    private List<FsqPlace> results;

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class FsqPlace {
        @JsonProperty("fsq_id")
        private String fsqId;

        private String name;
        private Double rating;
        private Integer price;

        private List<FsqCategory> categories;
        private FsqGeocodes geocodes;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class FsqCategory {
        private String name;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class FsqGeocodes {
        private FsqLatLng main;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class FsqLatLng {
        private Double latitude;
        private Double longitude;
    }
}