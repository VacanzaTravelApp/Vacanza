package com.vacanza.backend.entity;

import com.vacanza.backend.entity.enums.InteractionType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UuidGenerator;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

/** Davranış takibi: alan seçimi, POI görüntüleme, kategori filtre vb. */
@Entity
@Table(name = "user_interactions", indexes = {
        @Index(name = "idx_user_interactions_user_id", columnList = "user_id"),
        @Index(name = "idx_user_interactions_type", columnList = "interaction_type"),
        @Index(name = "idx_user_interactions_created_at", columnList = "created_at")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserInteraction {

    @Id
    @GeneratedValue
    @UuidGenerator
    @Column(name = "interaction_id", nullable = false, updatable = false)
    private UUID interactionId;

    // FK: users.user_id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "interaction_type", nullable = false, length = 40)
    private InteractionType interactionType;

    @Column(name = "target_id", length = 36)
    private UUID targetId;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "metadata", columnDefinition = "jsonb")
    private Map<String, Object> metadata;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    protected void onCreate() {
        if (this.createdAt == null) {
            this.createdAt = Instant.now();
        }
    }
}
