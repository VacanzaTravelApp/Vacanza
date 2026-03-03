package com.vacanza.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

/**
 * AI-inferred user preferences stored as flexible key-value pairs.
 * Unlike UserPreferences (explicit, UI-driven), these are discovered
 * through AI conversations or behavioral analysis.
 */
@Entity
@Table(name = "user_preferences_ai", uniqueConstraints = {
        @UniqueConstraint(name = "uk_user_preferences_ai_user_key",
                columnNames = {"user_id", "preference_key"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserPreferenceAi {

    @Id
    @GeneratedValue
    @UuidGenerator
    @Column(name = "preference_id", nullable = false, updatable = false)
    private UUID preferenceId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "preference_key", nullable = false, length = 100)
    private String preferenceKey;

    @Column(name = "preference_value", nullable = false, length = 500)
    private String preferenceValue;

    /**
     * AI confidence score for this preference (0.0 - 1.0).
     * Higher values mean the AI is more certain about the inferred preference.
     */
    @Column(name = "confidence", nullable = false)
    private Double confidence;

    /**
     * Where this preference was learned from.
     * e.g. "conversation", "ui", "behavior"
     */
    @Column(name = "source", nullable = false, length = 50)
    private String source;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    protected void onCreate() {
        if (this.updatedAt == null) {
            this.updatedAt = Instant.now();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = Instant.now();
    }
}
