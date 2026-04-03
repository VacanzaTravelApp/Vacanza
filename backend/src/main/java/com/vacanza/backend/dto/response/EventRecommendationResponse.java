package com.vacanza.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EventRecommendationResponse {

    private String message;
    private List<RecommendedEvent> events;
    private int totalFound;
    private boolean hasRecommendations;
}
