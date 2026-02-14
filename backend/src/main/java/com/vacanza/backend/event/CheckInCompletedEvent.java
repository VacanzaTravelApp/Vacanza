package com.vacanza.backend.event;

import com.vacanza.backend.entity.enums.CheckInSource;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.time.Instant;
import java.util.UUID;

/**
 * Domain event published after a successful check-in is persisted.
 * Consumed by gamification (and potentially other) listeners.
 */
@Getter
@AllArgsConstructor
@Builder
public class CheckInCompletedEvent {
    private final UUID checkInId;
    private final UUID userId;
    private final UUID poiId;
    private final String poiName;
    private final Instant checkedInAt;
    private final CheckInSource source;
}
