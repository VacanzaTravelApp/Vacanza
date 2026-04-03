package com.vacanza.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecommendedEvent {

    private String id;
    private String name;
    private String description;
    private String thumbnail;
    private String startTime;
    private String endTime;
    private String venueName;
    private String fullAddress;
    private Double latitude;
    private Double longitude;
    private String category;
    private String ticketLink;
    private Integer matchedDay;
    private String matchReason;
    private Double relevanceScore;
}
