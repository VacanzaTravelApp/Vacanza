package com.vacanza.backend.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.vacanza.backend.dto.adjustment.RouteUpdatedNotification;
import com.vacanza.backend.event.ItineraryAdjustmentEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * Manages Server-Sent Event connections and pushes real-time itinerary update
 * notifications to subscribed clients.
 *
 * <p>Each user may have multiple concurrent connections (multiple browser tabs
 * or app sessions). All active emitters for a user receive the event.
 *
 * <p>SSE emitters have a 5-minute timeout; clients are expected to reconnect
 * automatically on disconnect (standard SSE behaviour).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SseNotificationService {

    private static final long SSE_TIMEOUT_MS = 5 * 60 * 1000L; // 5 minutes

    private final ObjectMapper objectMapper;

    /** userId → list of active emitters. */
    private final ConcurrentHashMap<UUID, CopyOnWriteArrayList<SseEmitter>> emitters =
            new ConcurrentHashMap<>();

    /**
     * Creates and registers a new SSE emitter for the given user.
     * Called from the controller when a client connects to {@code GET /api/routes/adjustment-stream}.
     */
    public SseEmitter subscribe(UUID userId) {
        SseEmitter emitter = new SseEmitter(SSE_TIMEOUT_MS);
        emitters.computeIfAbsent(userId, k -> new CopyOnWriteArrayList<>()).add(emitter);

        Runnable cleanup = () -> removeEmitter(userId, emitter);
        emitter.onCompletion(cleanup);
        emitter.onTimeout(cleanup);
        emitter.onError(e -> {
            log.debug("SSE emitter error for user {}: {}", userId, e.getMessage());
            cleanup.run();
        });

        log.debug("SSE subscribed for user {} (total emitters: {})",
                userId, emitters.getOrDefault(userId, new CopyOnWriteArrayList<>()).size());
        return emitter;
    }

    /**
     * Listens for {@link ItineraryAdjustmentEvent} published after a DB commit and
     * pushes a JSON notification to all active SSE connections for the affected user.
     */
    @Async
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onAdjustmentCompleted(ItineraryAdjustmentEvent event) {
        RouteUpdatedNotification notification = RouteUpdatedNotification.builder()
                .originalRouteId(event.getOriginalRouteId())
                .newRouteId(event.getNewRouteId())
                .version(event.getNewVersion())
                .triggerType(event.getTriggerType().name())
                .userMessage(event.getUserMessage())
                .success(event.isSuccess())
                .build();

        pushToUser(event.getUserId(), "route_updated", notification);
    }

    // ── Internal helpers ────────────────────────────────────────────────────

    private void pushToUser(UUID userId, String eventName, Object payload) {
        List<SseEmitter> userEmitters = emitters.get(userId);
        if (userEmitters == null || userEmitters.isEmpty()) {
            log.debug("No SSE subscribers for user {} — skipping push", userId);
            return;
        }

        String json;
        try {
            json = objectMapper.writeValueAsString(payload);
        } catch (JsonProcessingException e) {
            log.error("Failed to serialise SSE payload: {}", e.getMessage());
            return;
        }

        List<SseEmitter> dead = new java.util.ArrayList<>();
        for (SseEmitter emitter : userEmitters) {
            try {
                emitter.send(SseEmitter.event().name(eventName).data(json));
            } catch (IOException e) {
                log.debug("SSE send failed for user {} — marking emitter for removal", userId);
                dead.add(emitter);
            }
        }
        dead.forEach(e -> removeEmitter(userId, e));

        log.info("[SSE] Pushed '{}' to user {} ({} emitters)", eventName, userId, userEmitters.size() - dead.size());
    }

    private void removeEmitter(UUID userId, SseEmitter emitter) {
        CopyOnWriteArrayList<SseEmitter> list = emitters.get(userId);
        if (list != null) {
            list.remove(emitter);
            if (list.isEmpty()) {
                emitters.remove(userId);
            }
        }
    }
}
