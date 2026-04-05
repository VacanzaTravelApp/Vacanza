package com.vacanza.backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * Request DTO for event search via Ticketmaster Discovery API.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class EventSearchRequestDTO {

    /**
     * City to search events in (e.g., "Istanbul", "Paris").
     */
    @NotBlank(message = "City is required")
    private String city;

    /**
     * ISO country code (e.g., "TR", "US", "FR"). Optional.
     */
    private String countryCode;

    /**
     * Optional geo center for Ticketmaster {@code latlong} (from route waypoint). Use with {@link #geoLongitude}.
     */
    private Double geoLatitude;

    /**
     * Optional geo center for Ticketmaster {@code latlong} (from route waypoint). Use with {@link #geoLatitude}.
     */
    private Double geoLongitude;

    /**
     * Start date for the event search range. Optional.
     */
    private LocalDate startDate;

    /**
     * End date for the event search range. Optional.
     */
    private LocalDate endDate;

    /**
     * Event category/classification (e.g., "music", "sports", "arts", "family").
     * Optional — if null, all categories are returned.
     */
    private String category;

    /**
     * Number of results to return (default: 20, max: 50).
     */
    private Integer size;
}
