package com.vacanza.backend.integration.booking;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Represents a single airport/city suggestion returned by SerpApi's
 * google_flights_autocomplete engine.
 *
 * <p>GET /search.json?engine=google_flights_autocomplete&amp;q={query}&amp;api_key=...
 *
 * <p>The response contains an "airports" array. Each entry can represent an airport
 * or a city hub with multiple airports. We flatten these into individual suggestions.
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class SerpApiAirportSuggestion {

    /** IATA airport/city code (e.g. "IST"). */
    private String iataCode;

    /** Full airport name (e.g. "Istanbul Airport"). */
    private String name;

    /** City name (e.g. "Istanbul"). */
    private String city;

    /** Country name (e.g. "Turkey"). */
    private String country;

    /**
     * Google Knowledge Graph ID (e.g. "/m/0203v").
     * Can be used as departure_id/arrival_id in Google Flights searches
     * to represent an entire city (all airports).
     */
    private String kgmid;

    // ─── SerpApi response shape ───────────────────────────────────────────────

    /** Raw SerpApi "airports" array wrapper. */
    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class AutocompleteResponse {

        @JsonProperty("airports")
        private List<AirportEntry> airports;
    }

    /** Top-level entry — may represent a city cluster with child airports. */
    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class AirportEntry {

        @JsonProperty("id")
        private String id;       // IATA or kgmid

        @JsonProperty("name")
        private String name;     // city / airport name shown first

        @JsonProperty("city")
        private String city;

        @JsonProperty("country")
        private String country;

        /** Sub-airports within a city cluster (may be null). */
        @JsonProperty("airports")
        private List<SubAirport> airports;
    }

    /** Individual airport within a city cluster. */
    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class SubAirport {

        @JsonProperty("id")
        private String id;      // IATA code

        @JsonProperty("name")
        private String name;    // airport name
    }

    // ─── Mapping ─────────────────────────────────────────────────────────────

    /**
     * Converts a raw SerpApi autocomplete response into a flat list of
     * {@link SerpApiAirportSuggestion} objects suitable for the frontend.
     *
     * <p>Logic:
     * <ol>
     *   <li>If an entry has child airports, emit one suggestion per child airport
     *       (inheriting city/country from the parent).</li>
     *   <li>If an entry has no child airports (it IS the airport), emit it directly.</li>
     * </ol>
     */
    public static List<SerpApiAirportSuggestion> fromResponse(AutocompleteResponse response) {
        if (response == null || response.getAirports() == null) {
            return Collections.emptyList();
        }

        List<SerpApiAirportSuggestion> suggestions = new ArrayList<>();

        for (AirportEntry entry : response.getAirports()) {
            if (entry.getAirports() != null && !entry.getAirports().isEmpty()) {
                // City cluster: emit each sub-airport, keep kgmid on parent only
                for (SubAirport sub : entry.getAirports()) {
                    SerpApiAirportSuggestion s = new SerpApiAirportSuggestion();
                    s.setIataCode(sub.getId());
                    s.setName(sub.getName());
                    s.setCity(entry.getCity() != null ? entry.getCity() : entry.getName());
                    s.setCountry(entry.getCountry());
                    suggestions.add(s);
                }
                // Also add the city itself so users can search "all airports in X"
                SerpApiAirportSuggestion city = new SerpApiAirportSuggestion();
                city.setIataCode(entry.getId());
                city.setName("All airports — " + (entry.getCity() != null ? entry.getCity() : entry.getName()));
                city.setCity(entry.getCity() != null ? entry.getCity() : entry.getName());
                city.setCountry(entry.getCountry());
                city.setKgmid(entry.getId() != null && entry.getId().startsWith("/m/") ? entry.getId() : null);
                suggestions.add(city);
            } else {
                // Direct airport entry
                SerpApiAirportSuggestion s = new SerpApiAirportSuggestion();
                s.setIataCode(entry.getId());
                s.setName(entry.getName());
                s.setCity(entry.getCity());
                s.setCountry(entry.getCountry());
                suggestions.add(s);
            }
        }

        return suggestions;
    }
}
