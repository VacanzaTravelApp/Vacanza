package com.vacanza.backend.integration;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Foursquare Places API v3 response DTOs.
 * Covers both /places/search (list) and /places/{fsq_id} (detail) endpoints.
 */
public class FoursquareResponse {

    // ---------- Search response (list) ----------

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class SearchResult {
        private List<Place> results;
    }

    // ---------- Place detail ----------

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Place {
        @JsonProperty("fsq_id")
        private String fsqId;

        private String name;
        private Location location;
        private List<Category> categories;

        /** 0–10 scale rating (Premium field). */
        private Double rating;

        /** 1–4 price tier (Premium field). */
        private Integer price;

        /** Regular opening hours (Premium field). */
        @JsonProperty("hours")
        private Hours hours;
    }

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Location {
        private Double latitude;
        private Double longitude;
        private String address;
        @JsonProperty("formatted_address")
        private String formattedAddress;
    }

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Category {
        private int id;
        private String name;
        @JsonProperty("short_name")
        private String shortName;
    }

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Hours {
        private String display;
        @JsonProperty("open_now")
        private Boolean openNow;
        private List<Regular> regular;
    }

    @Data
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Regular {
        /** 1=Mon … 7=Sun */
        private int day;
        private String open;
        private String close;
    }
}
