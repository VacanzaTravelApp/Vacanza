package com.vacanza.backend.controller;

import com.vacanza.backend.dto.adjustment.AdjustmentResult;
import com.vacanza.backend.dto.adjustment.AdjustmentTriggerRequest;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.security.CurrentUserProvider;
import com.vacanza.backend.service.ItineraryAdjustmentService;
import com.vacanza.backend.service.SseNotificationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.UUID;

/**
 * REST surface for FReq5 — Adaptive Itinerary Adjustment.
 *
 * <h3>Endpoints</h3>
 * <ul>
 *   <li>{@code POST /api/routes/{routeId}/adjust} — trigger an adjustment</li>
 *   <li>{@code GET  /api/routes/adjustment-stream} — SSE stream for real-time updates</li>
 * </ul>
 *
 * <h3>Security</h3>
 * All endpoints require a valid Firebase Bearer token. Adjustments are user-scoped:
 * a user can only adjust routes they own (enforced by the service layer via
 * {@code findByRouteIdAndUser}).
 *
 * <h3>SLA</h3>
 * Synchronous path ({@code async=false}, default): the response is returned after
 * deterministic replanning completes, targeting ≤ 10 seconds.
 * Async path ({@code async=true}): HTTP 202 is returned immediately; the updated route
 * is pushed via the SSE stream when ready.
 */
@Slf4j
@RestController
@RequestMapping("/api/routes")
@RequiredArgsConstructor
public class ItineraryAdjustmentController {

    private final ItineraryAdjustmentService adjustmentService;
    private final SseNotificationService sseService;
    private final CurrentUserProvider currentUserProvider;

    /**
     * Trigger an adaptive adjustment for a saved route.
     *
     * <p>Request body example:
     * <pre>{@code
     * {
     *   "triggerType": "USER_REPORTED",
     *   "severity": "HIGH",
     *   "reason": "Golden Gate Bridge is closed for maintenance",
     *   "affectedPoiName": "Golden Gate Bridge",
     *   "affectedDay": 1
     * }
     * }</pre>
     *
     * @param routeId target route UUID
     * @param async   when {@code true}, returns 202 immediately and processes in background
     * @param req     trigger details
     */
    @PostMapping("/{routeId}/adjust")
    public ResponseEntity<AdjustmentResult> adjust(
            @PathVariable UUID routeId,
            @RequestParam(defaultValue = "false") boolean async,
            @Valid @RequestBody AdjustmentTriggerRequest req) {

        User user = currentUserProvider.getCurrentUserEntity();

        log.info("[ADAPTIVE] Adjustment request: routeId={} triggerType={} poi='{}' async={}",
                routeId, req.getTriggerType(), req.getAffectedPoiName(), async);

        if (async) {
            adjustmentService.triggerAsync(routeId, user, req);
            AdjustmentResult accepted = AdjustmentResult.builder()
                    .originalRouteId(routeId)
                    .async(true)
                    .userMessage("Adjustment is being processed. You will be notified via the update stream.")
                    .idempotencyKey(null)
                    .build();
            return ResponseEntity.accepted().body(accepted);
        }

        AdjustmentResult result = adjustmentService.adjust(routeId, user, req);
        return ResponseEntity.ok(result);
    }

    /**
     * Server-Sent Events stream for real-time itinerary update notifications.
     *
     * <p>The client should establish this connection once on app start. Events named
     * {@code route_updated} are pushed whenever an adaptive adjustment completes.
     *
     * <p>Example client (JS):
     * <pre>{@code
     * const es = new EventSource('/api/routes/adjustment-stream', { withCredentials: true });
     * es.addEventListener('route_updated', e => {
     *   const data = JSON.parse(e.data);
     *   // data.newRouteId — reload route from /api/routes/{newRouteId}
     * });
     * }</pre>
     */
    @GetMapping(value = "/adjustment-stream")
    public ResponseEntity<SseEmitter> adjustmentStream() {
        User user;
        try {
            user = currentUserProvider.getCurrentUserEntity();
        } catch (Exception e) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.UNAUTHORIZED).build();
        }
        log.debug("[SSE] New adjustment stream connection for user {}", user.getUserId());
        SseEmitter emitter = sseService.subscribe(user.getUserId());
        return ResponseEntity.ok()
                .header("Content-Type", MediaType.TEXT_EVENT_STREAM_VALUE)
                .header("Cache-Control", "no-cache")
                .header("X-Accel-Buffering", "no")
                .body(emitter);
    }
}
