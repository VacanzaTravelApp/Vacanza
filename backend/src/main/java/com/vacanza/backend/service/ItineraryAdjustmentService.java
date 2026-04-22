package com.vacanza.backend.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vacanza.backend.dto.adjustment.AdjustmentResult;
import com.vacanza.backend.dto.adjustment.AdjustmentTriggerRequest;
import com.vacanza.backend.entity.AiRoute;
import com.vacanza.backend.entity.RouteHotel;
import com.vacanza.backend.entity.RouteAdjustmentLog;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.enums.AdjustmentSeverity;
import com.vacanza.backend.event.ItineraryAdjustmentEvent;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;
import com.vacanza.backend.integration.ai.AiChatDto;
import com.vacanza.backend.repo.AiRouteRepository;
import com.vacanza.backend.repo.RouteAdjustmentLogRepository;
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Tags;
import io.micrometer.core.instrument.Timer;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

/**
 * Orchestrates the adaptive itinerary adjustment pipeline:
 *
 * <ol>
 *   <li>Idempotency guard — return early if same trigger already processed today.</li>
 *   <li>Load and authorise the target route.</li>
 *   <li>Delegate to {@link DeterministicReplannerService} (no LLM — stays under SLA).</li>
 *   <li>Persist the updated route as a new version row in {@code ai_routes}.</li>
 *   <li>Mark the audit log entry {@code COMPLETED}.</li>
 *   <li>Publish {@link ItineraryAdjustmentEvent} for SSE push.</li>
 * </ol>
 *
 * <p>The {@code #triggerAsync} entry point runs in a background thread, keeping the HTTP
 * response under 200 ms for fire-and-forget callers while deterministic processing
 * completes in < 10 seconds.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ItineraryAdjustmentService {

    private final AiRouteRepository routeRepository;
    private final RouteAdjustmentLogRepository logRepository;
    private final DeterministicReplannerService replanner;
    private final ApplicationEventPublisher eventPublisher;
    private final ObjectMapper objectMapper;
    private final ObjectProvider<MeterRegistry> meterRegistry;

    // ── Public API ──────────────────────────────────────────────────────────

    /**
     * Synchronous adjustment — blocks until complete (≤ 10 s target).
     * Called from the REST controller when {@code async=false} (default).
     */
    @Transactional
    public AdjustmentResult adjust(UUID routeId, User user, AdjustmentTriggerRequest req) {
        Timer.Sample sample = startTimer();

        AiRoute route = loadAndAuthorise(routeId, user);
        String idempotencyKey = buildIdempotencyKey(req, routeId);

        // Idempotency: if already processed today, return the existing result
        Optional<RouteAdjustmentLog> existing = logRepository.findByIdempotencyKey(idempotencyKey);
        if (existing.isPresent()) {
            RouteAdjustmentLog prev = existing.get();
            if ("COMPLETED".equals(prev.getStatus()) || "SKIPPED".equals(prev.getStatus())) {
                log.info("[ADAPTIVE] Idempotent hit for key {} → returning cached result", idempotencyKey);
                return buildSkippedResult(routeId, idempotencyKey, prev);
            }
        }

        RouteAdjustmentLog auditLog = createPendingLog(route, user, req, idempotencyKey);

        try {
            AdjustmentResult result = executeAdjustment(route, req, auditLog, idempotencyKey);
            stopTimer(sample, "success");
            return result;
        } catch (Exception e) {
            failLog(auditLog, e.getMessage());
            stopTimer(sample, "error");
            throw e;
        }
    }

    /**
     * Async variant: returns immediately with {@code async=true} in the result, then
     * processes in a background thread. The client should listen on the SSE stream for
     * the {@code route_updated} event.
     */
    @Async
    public void triggerAsync(UUID routeId, User user, AdjustmentTriggerRequest req) {
        try {
            adjust(routeId, user, req);
        } catch (Exception e) {
            log.error("[ADAPTIVE] Async adjustment failed for route {}: {}", routeId, e.getMessage(), e);
        }
    }

    // ── Core pipeline ────────────────────────────────────────────────────────

    private AdjustmentResult executeAdjustment(
            AiRoute route,
            AdjustmentTriggerRequest req,
            RouteAdjustmentLog auditLog,
            String idempotencyKey) {

        // Parse current route JSON
        AiChatDto.RouteData routeData;
        try {
            routeData = objectMapper.readValue(route.getRouteJson(), AiChatDto.RouteData.class);
        } catch (Exception e) {
            throw new IllegalStateException("Failed to parse route JSON for route " + route.getRouteId(), e);
        }

        // Collect POI names rejected in ancestor adjustments so the replanner won't recycle them
        Set<String> historicallyExcluded = collectHistoricallyExcludedNames(route);

        // Run deterministic replanning
        List<AdjustmentResult.WaypointActionSummary> actions =
                replanner.replan(routeData, req.getAffectedPoiName(), req.getAffectedDay(), req.getSeverity(), historicallyExcluded);

        if (actions.isEmpty()) {
            log.info("[ADAPTIVE] No waypoints matched '{}' in route {} — skipping save",
                    req.getAffectedPoiName(), route.getRouteId());
            auditLog.setStatus("SKIPPED");
            auditLog.setCompletedAt(LocalDateTime.now());
            logRepository.save(auditLog);
            return AdjustmentResult.builder()
                    .originalRouteId(route.getRouteId())
                    .newRouteId(route.getRouteId())
                    .version(route.getVersion())
                    .async(false)
                    .actions(actions)
                    .userMessage("No changes needed — the affected stop was not found in your itinerary.")
                    .idempotencyKey(idempotencyKey)
                    .build();
        }

        // Serialise updated route
        String updatedJson;
        try {
            updatedJson = objectMapper.writeValueAsString(routeData);
        } catch (Exception e) {
            throw new IllegalStateException("Failed to serialise updated route JSON", e);
        }

        String adjustmentReason = buildAdjustmentReason(req, actions);
        int newVersion = route.getVersion() + 1;

        // Persist new version
        RouteHotel parentHotel = route.getSelectedHotel();
        RouteHotel copiedHotel = parentHotel == null ? null : RouteHotel.builder()
                .hotelName(parentHotel.getHotelName())
                .hotelExternalId(parentHotel.getHotelExternalId())
                .address(parentHotel.getAddress())
                .latitude(parentHotel.getLatitude())
                .longitude(parentHotel.getLongitude())
                .imageUrl(parentHotel.getImageUrl())
                .externalBookingUrl(parentHotel.getExternalBookingUrl())
                .pricePerNight(parentHotel.getPricePerNight())
                .currency(parentHotel.getCurrency())
                .rating(parentHotel.getRating())
                .providerName(parentHotel.getProviderName())
                .build();

        AiRoute newRoute = AiRoute.builder()
                .user(route.getUser())
                .conversationId(route.getConversationId())
                .title(route.getTitle())
                .destination(route.getDestination())
                .totalDays(route.getTotalDays())
                .routeJson(updatedJson)
                .version(newVersion)
                .parentRouteId(route.getRouteId())
                .adjustedAt(LocalDateTime.now())
                .adjustmentReason(adjustmentReason)
                .selectedHotel(copiedHotel)
                .build();
        AiRoute saved = routeRepository.save(newRoute);

        // Mark audit log as completed
        auditLog.setStatus("COMPLETED");
        auditLog.setResultRouteId(saved.getRouteId());
        auditLog.setCompletedAt(LocalDateTime.now());
        logRepository.save(auditLog);

        String userMessage = buildUserMessage(req, actions);

        // Publish event for SSE push (after commit via @TransactionalEventListener)
        eventPublisher.publishEvent(ItineraryAdjustmentEvent.builder()
                .originalRouteId(route.getRouteId())
                .newRouteId(saved.getRouteId())
                .userId(route.getUser().getUserId())
                .triggerType(req.getTriggerType())
                .severity(req.getSeverity())
                .newVersion(newVersion)
                .userMessage(userMessage)
                .success(true)
                .build());

        log.info("[ADAPTIVE] Route {} → new version {} (id={}) with {} actions",
                route.getRouteId(), newVersion, saved.getRouteId(), actions.size());

        return AdjustmentResult.builder()
                .originalRouteId(route.getRouteId())
                .newRouteId(saved.getRouteId())
                .version(newVersion)
                .async(false)
                .actions(actions)
                .userMessage(userMessage)
                .idempotencyKey(idempotencyKey)
                .build();
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    private AiRoute loadAndAuthorise(UUID routeId, User user) {
        return routeRepository.findByRouteIdAndUser(routeId, user)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Route " + routeId + " not found or not owned by this user"));
    }

    private RouteAdjustmentLog createPendingLog(
            AiRoute route, User user,
            AdjustmentTriggerRequest req,
            String idempotencyKey) {
        try {
            RouteAdjustmentLog log = RouteAdjustmentLog.builder()
                    .routeId(route.getRouteId())
                    .userId(user.getUserId())
                    .triggerType(req.getTriggerType())
                    .severity(req.getSeverity())
                    .affectedPoiName(req.getAffectedPoiName())
                    .reason(req.getReason())
                    .idempotencyKey(idempotencyKey)
                    .status("PENDING")
                    .build();
            return logRepository.save(log);
        } catch (DataIntegrityViolationException e) {
            // Race condition: another request already inserted the same key
            throw new IllegalStateException("Duplicate adjustment trigger: " + idempotencyKey);
        }
    }

    private void failLog(RouteAdjustmentLog auditLog, String errorMessage) {
        auditLog.setStatus("FAILED");
        auditLog.setErrorMessage(errorMessage);
        auditLog.setCompletedAt(LocalDateTime.now());
        logRepository.save(auditLog);
    }

    private static String buildIdempotencyKey(AdjustmentTriggerRequest req, UUID routeId) {
        String poi = req.getAffectedPoiName() != null ? req.getAffectedPoiName() : "ALL";
        return req.getTriggerType().name() + ":" + routeId + ":" + poi + ":" + LocalDate.now();
    }

    private static String buildAdjustmentReason(
            AdjustmentTriggerRequest req,
            List<AdjustmentResult.WaypointActionSummary> actions) {
        String reason = req.getReason() != null ? req.getReason() : req.getTriggerType().name();
        long replaced = actions.stream().filter(a -> "REPLACED".equals(a.getAction())).count();
        long removed  = actions.stream().filter(a -> "REMOVED".equals(a.getAction())).count();
        return String.format("%s — %d replaced, %d removed", reason, replaced, removed);
    }

    private static String buildUserMessage(
            AdjustmentTriggerRequest req,
            List<AdjustmentResult.WaypointActionSummary> actions) {
        long replaced = actions.stream().filter(a -> "REPLACED".equals(a.getAction())).count();
        long removed  = actions.stream().filter(a -> "REMOVED".equals(a.getAction())).count();
        long marked   = actions.stream().filter(a -> "MARKED_UNAVAILABLE".equals(a.getAction())).count();

        StringBuilder sb = new StringBuilder("Your itinerary has been updated");
        if (req.getReason() != null) sb.append(" (").append(req.getReason()).append(")");
        sb.append(": ");
        if (replaced > 0) sb.append(replaced).append(" stop(s) replaced");
        if (removed  > 0) sb.append(replaced > 0 ? ", " : "").append(removed).append(" stop(s) removed");
        if (marked   > 0) sb.append((replaced + removed) > 0 ? ", " : "").append(marked).append(" stop(s) flagged unavailable");
        sb.append(".");
        return sb.toString();
    }

    private static AdjustmentResult buildSkippedResult(
            UUID routeId, String idempotencyKey, RouteAdjustmentLog prev) {
        return AdjustmentResult.builder()
                .originalRouteId(routeId)
                .newRouteId(prev.getResultRouteId() != null ? prev.getResultRouteId() : routeId)
                .version(0)
                .async(false)
                .actions(List.of())
                .userMessage("This adjustment was already applied.")
                .idempotencyKey(idempotencyKey)
                .build();
    }

    /**
     * Walks the parent route chain and collects every {@code affectedPoiName} that was
     * previously rejected in an adjustment. The replanner uses this set to ensure a
     * once-rejected POI (e.g. "Cafe A") is never recycled as a replacement in subsequent
     * adjustments within the same version chain.
     */
    private Set<String> collectHistoricallyExcludedNames(AiRoute route) {
        Set<String> excluded = new HashSet<>();
        UUID ancestorId = route.getParentRouteId();
        int depth = 0;
        while (ancestorId != null && depth < 20) {
            final UUID id = ancestorId;
            logRepository.findByRouteIdOrderByCreatedAtDesc(id).stream()
                    .map(RouteAdjustmentLog::getAffectedPoiName)
                    .filter(name -> name != null && !name.isBlank())
                    .forEach(name -> excluded.add(name.toLowerCase(Locale.ROOT)));

            ancestorId = routeRepository.findById(ancestorId)
                    .map(r -> r.getParentRouteId())
                    .orElse(null);
            depth++;
        }
        if (!excluded.isEmpty()) {
            log.debug("[ADAPTIVE] Historically excluded POIs for route {}: {}", route.getRouteId(), excluded);
        }
        return excluded;
    }

    // ── Metrics ─────────────────────────────────────────────────────────────

    private Timer.Sample startTimer() {
        return meterRegistry.getIfAvailable() != null
                ? Timer.start(meterRegistry.getIfAvailable())
                : null;
    }

    private void stopTimer(Timer.Sample sample, String outcome) {
        if (sample == null) return;
        meterRegistry.ifAvailable(mr ->
                sample.stop(mr.timer("itinerary.adjustment.duration",
                        Tags.of("outcome", outcome))));
    }
}
