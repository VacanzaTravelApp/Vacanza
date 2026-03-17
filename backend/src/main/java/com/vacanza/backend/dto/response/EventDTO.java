package com.vacanza.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Response DTO representing a single event.
 * Maps to the Events entity defined in the SRS.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EventDTO {

    private String id;
    private String name;
    private String description;
    private String link;
    private String thumbnail;
    private String startTime;
    private String endTime;
    private String city;
    private String country;
    private Double latitude;
    private Double longitude;
    private String venueName;
    private String fullAddress;
    private String category;
    private Boolean isVirtual;
    private String ticketLink;
}
