package com.vacanza.backend.dto.adjustment;

import lombok.Builder;
import lombok.Data;

import java.util.List;
import java.util.UUID;

/**
 * Response for {@code POST /api/routes/{routeId}/adjust}.
 */
@Data
@Builder
public class AdjustmentResult {

    /** New route version UUID (null when {@code async=true} and still processing). */
    private UUID newRouteId;

    /** Original route UUID that was adjusted. */
    private UUID originalRouteId;

    /** Version number of the new route. */
    private int version;

    /** True when processing was dispatched asynchronously (client should listen on SSE). */
    private boolean async;

    /** How the planner handled each affected stop. */
    private List<WaypointActionSummary> actions;

    /** User-facing message describing what changed. */
    private String userMessage;

    /** Idempotency key — clients can re-submit safely with the same key. */
    private String idempotencyKey;

    @Data
    @Builder
    public static class WaypointActionSummary {
        private String poiName;
        private int day;
        /** REPLACED, REMOVED, MARKED_UNAVAILABLE, KEPT */
        private String action;
        /** Name of the replacement POI when action = REPLACED. */
        private String replacementName;
    }
}
