package com.vacanza.backend.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

/**
 * Request body for {@code POST /chat/routes/replan-day-from-polygon}.
 * Replaces one day of the conversation's latest saved route using POIs inside the drawn polygon.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReplanDayFromPolygonRequest {

    /** Existing chat conversation that already has a saved route. */
    private UUID conversationId;

    /** 1-based day index to replace (must exist on the saved route). */
    private Integer day;

    /** Outer ring [lon, lat] pairs (same as polygon route). */
    private List<List<Double>> coordinates;

    private String travelStyle;

    private List<String> categories;
}
