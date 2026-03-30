package com.vacanza.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Destination suggestion for hotel search autocomplete.
 * Derived from airport autocomplete data — no extra SerpAPI call needed.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DestinationSuggestionDTO {

    /** City name (e.g. "Istanbul"). */
    private String city;

    /** Country name (e.g. "Turkey"). */
    private String country;

    /**
     * Display label for the frontend dropdown.
     * Example: "Istanbul, Turkey"
     */
    private String displayName;

    /**
     * Pre-built hotel search query ready for SerpAPI.
     * Example: "Hotels in Istanbul"
     */
    private String searchQuery;
}
