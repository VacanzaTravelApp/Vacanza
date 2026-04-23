package com.vacanza.backend.dto.adjustment;

import com.vacanza.backend.entity.enums.AdjustmentSeverity;
import com.vacanza.backend.entity.enums.AdjustmentTriggerType;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * Request body for {@code POST /api/routes/{routeId}/adjust}.
 *
 * <p>Callers may be:
 * <ul>
 *   <li>The mobile app (user tapped "this place is closed") → {@code triggerType = USER_REPORTED}</li>
 *   <li>An internal scheduler (weather alert) → {@code triggerType = WEATHER_ALERT}</li>
 *   <li>An operator webhook (POI closure) → {@code triggerType = POI_CLOSURE}</li>
 * </ul>
 *
 * <p>{@code affectedPoiName} is optional. When null the entire affected day is re-evaluated.
 * {@code affectedDay} is optional; when null the service scans all days for the named POI.
 */
@Data
public class AdjustmentTriggerRequest {

    @NotNull
    private AdjustmentTriggerType triggerType;

    @NotNull
    private AdjustmentSeverity severity;

    /**
     * Human-readable reason surfaced to the user (e.g. "Heavy rain expected on Day 2").
     */
    private String reason;

    /**
     * Name of the specific POI that is unavailable.
     * If null and {@code affectedDay} is also null, the whole route is re-evaluated.
     */
    private String affectedPoiName;

    /**
     * Day number (1-based) where the issue occurs. Optional — if null the service
     * will locate the POI across all days.
     */
    private Integer affectedDay;
}
