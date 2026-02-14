package com.vacanza.backend.event;

import com.vacanza.backend.service.GamificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Listens for {@link CheckInCompletedEvent} after transaction commit
 * and triggers the gamification service in a best-effort, non-blocking manner.
 *
 * <ul>
 * <li>Runs after transaction commit (AFTER_COMMIT) — ensures check-in is
 * persisted first</li>
 * <li>Runs asynchronously (@Async) — does not block the check-in response</li>
 * <li>Catches all exceptions — gamification failures never affect the check-in
 * flow</li>
 * </ul>
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class GamificationEventListener {

    private final GamificationService gamificationService;

    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onCheckInCompleted(CheckInCompletedEvent event) {
        try {
            log.debug("Processing gamification for checkInId={}", event.getCheckInId());
            gamificationService.processCheckIn(event);
        } catch (Exception e) {
            log.error("Gamification hook failed for checkInId={}, userId={}, poiId={}: {}",
                    event.getCheckInId(), event.getUserId(), event.getPoiId(), e.getMessage(), e);
        }
    }
}
