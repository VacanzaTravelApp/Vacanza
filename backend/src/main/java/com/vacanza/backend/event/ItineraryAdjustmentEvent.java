package com.vacanza.backend.event;

import com.vacanza.backend.entity.enums.AdjustmentSeverity;
import com.vacanza.backend.entity.enums.AdjustmentTriggerType;
import lombok.Builder;
import lombok.Getter;

import java.util.UUID;

/**
 * Spring application event published after a route adjustment has been persisted.
 * Consumed by {@code SseNotificationService} to push a real-time update to the user.
 *
 * <p>Published with {@code @TransactionalEventListener(phase = AFTER_COMMIT)} so the
 * new route version is guaranteed to be visible in the DB before the SSE frame is sent.
 */
@Getter
@Builder
public class ItineraryAdjustmentEvent {

    private final UUID originalRouteId;
    private final UUID newRouteId;
    private final UUID userId;
    private final AdjustmentTriggerType triggerType;
    private final AdjustmentSeverity severity;
    private final int newVersion;
    private final String userMessage;
    private final boolean success;
}
