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

    /**
     * Whether events were fetched for a broad month-long window or the narrow trip dates — use in UI to avoid
     * overwhelming users (e.g. collapse list, "add dates" CTA) when {@link EventSearchWindowMode#BROAD_30_DAYS}.
     */
    private EventSearchWindowMode eventSearchWindow;
}
