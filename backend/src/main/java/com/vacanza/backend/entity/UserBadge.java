package com.vacanza.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * Junction table: tracks which badges a user has earned and when.
 */
@Entity
@Table(name = "user_badges", uniqueConstraints = @UniqueConstraint(name = "uk_user_badge", columnNames = { "user_id",
        "badge_id" }))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserBadge {

    @Id
    @GeneratedValue
    @UuidGenerator
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "badge_id", nullable = false)
    private Badge badge;

    @Column(name = "earned_at", nullable = false)
    private Instant earnedAt;

    @PrePersist
    protected void onCreate() {
        if (this.earnedAt == null) {
            this.earnedAt = Instant.now();
        }
    }
}
