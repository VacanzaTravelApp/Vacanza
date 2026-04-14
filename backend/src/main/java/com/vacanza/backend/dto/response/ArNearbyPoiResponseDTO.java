package com.vacanza.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ArNearbyPoiResponseDTO {

    private UUID poiId;
    private String name;
    private String category;
    private Double latitude;
    private Double longitude;
    private Double distanceMeters;
    /** Foursquare / external id — aligns map + AR feedback keys with search-in-area. */
    private String externalId;
}

