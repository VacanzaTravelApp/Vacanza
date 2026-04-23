package com.vacanza.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UuidGenerator;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Audit log and idempotency guard for every itinerary adjustment attempt.
 *
 * <p>The {@code idempotency_key} unique constraint prevents the same external
 * trigger (e.g. same weather alert for the same route on the same calendar day)
 * from being processed more than once.
 *
 * <p>Key format: {@code <triggerType>:<routeId>:<affectedPoiName|ALL>:<YYYY-MM-DD>}
 */
@Entity
@Table(
        name = "route_adjustment_logs",
        indexes = {
                @Index(name = "idx_ral_route_id",   columnList = "route_id"),
                @Index(name = "idx_ral_user_id",    columnList = "user_id"),
                @Index(name = "idx_ral_created_at", columnList = "created_at")
        },
        uniqueConstraints = @UniqueConstraint(
                name = "uq_ral_idempotency_key",
                columnNames = "idempotency_key"
        )
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RouteAdjustmentLog {

    @Id
    @GeneratedValue
    @UuidGenerator
    @Column(name = "log_id", nullable = false, updatable = false)
    private UUID logId;

    /** Route that was the target of this adjustment. */
    @Column(name = "route_id", nullable = false)
    private UUID routeId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "trigger_type", nullable = false, length = 32)
    private com.vacanza.backend.entity.enums.AdjustmentTriggerType triggerType;

    @Enumerated(EnumType.STRING)
    @Column(name = "severity", nullable = false, length = 16)
    private com.vacanza.backend.entity.enums.AdjustmentSeverity severity;

    /** Name of the affected POI, or {@code null} if the trigger affects the whole day. */
    @Column(name = "affected_poi_name")
    private String affectedPoiName;

    /** Human-readable reason given by the trigger source. */
    @Column(name = "reason", length = 512)
    private String reason;

    /**
     * Deterministic key used to deduplicate identical triggers.
     * Format: {@code TRIGGER_TYPE:routeId:affectedPoiOrALL:YYYY-MM-DD}
     */
    @Column(name = "idempotency_key", nullable = false, unique = true, length = 256)
    private String idempotencyKey;

    /** Processing status. */
    @Column(name = "status", nullable = false, length = 16)
    private String status;   // PENDING | COMPLETED | FAILED | SKIPPED

    /** UUID of the new AiRoute version produced by this adjustment (null until COMPLETED). */
    @Column(name = "result_route_id")
    private UUID resultRouteId;

    @Column(name = "error_message", length = 1024)
    private String errorMessage;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
