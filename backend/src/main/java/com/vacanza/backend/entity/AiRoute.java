package com.vacanza.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UuidGenerator;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "ai_routes")
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

    @PrePersist
    protected void onCreate() {
        this.generatedAt = LocalDateTime.now();
    }
}
