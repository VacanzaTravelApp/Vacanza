package com.vacanza.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * Aggregated user × POI affinity (e.g. thumbs up/down), keyed by stable id prefix (fs:, mb:).
 */
@Entity
@Table(name = "user_poi_feedback", uniqueConstraints = {
        @UniqueConstraint(name = "uk_user_poi_feedback_user_key", columnNames = {"user_id", "poi_key"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserPoiFeedback {

    @Id
    @GeneratedValue
    @UuidGenerator
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "poi_key", nullable = false, length = 220)
    private String poiKey;

    /**
     * Running affinity; sign = like/dislike strength (bounded in service layer).
     */
    @Column(name = "score", nullable = false)
    private double score;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    @PreUpdate
    void touch() {
        this.updatedAt = Instant.now();
    }
}
