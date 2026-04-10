package com.vacanza.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UuidGenerator;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(
        name = "ai_routes",
        indexes = {
                @Index(name = "idx_ai_routes_user_id",         columnList = "user_id"),
                @Index(name = "idx_ai_routes_conversation_id", columnList = "conversation_id"),
                @Index(name = "idx_ai_routes_parent_route_id", columnList = "parent_route_id")
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AiRoute {

    @Id
    @GeneratedValue
    @UuidGenerator
    @Column(name = "route_id", nullable = false, updatable = false)
    private UUID routeId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "conversation_id")
    private UUID conversationId;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "destination")
    private String destination;

    @Column(name = "total_days")
    private int totalDays;

    @Column(name = "route_json", columnDefinition = "TEXT", nullable = false)
    private String routeJson;

    @Column(name = "generated_at", nullable = false, updatable = false)
    private LocalDateTime generatedAt;

    // ── Versioning & adjustment tracking ──────────────────────────────────────

    /**
     * Monotonically increasing version number. Version 1 = original AI-generated route.
     * Each adaptive adjustment increments this by 1 and writes a new row.
     */
    @Column(name = "version", nullable = false, columnDefinition = "integer default 1")
    @Builder.Default
    private int version = 1;

    /**
     * Points to the route_id of the immediately preceding version.
     * Null for version-1 routes.
     */
    @Column(name = "parent_route_id")
    private UUID parentRouteId;

    /** Timestamp of the most recent adaptive adjustment (null for original routes). */
    @Column(name = "adjusted_at")
    private LocalDateTime adjustedAt;

    /**
     * Human-readable reason for the last adjustment
     * (e.g. "Heavy rain on Day 2 — Golden Gate Bridge replaced with de Young Museum").
     */
    @Column(name = "adjustment_reason", length = 1024)
    private String adjustmentReason;

    @PrePersist
    protected void onCreate() {
        this.generatedAt = LocalDateTime.now();
    }
}
