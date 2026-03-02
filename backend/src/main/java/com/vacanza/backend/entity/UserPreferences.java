package com.vacanza.backend.entity;

import com.vacanza.backend.entity.enums.*;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UuidGenerator;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Explicit user preferences for AI personalization.
 * One-to-one with User (same pattern as UserInfo).
 */
@Entity
@Table(name = "user_preferences", uniqueConstraints = @UniqueConstraint(name = "uk_preferences_user", columnNames = "user_id"))
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserPreferences {

    @Id
    @GeneratedValue
    @UuidGenerator
    @Column(name = "preferences_id", nullable = false, updatable = false)
    private UUID preferencesId;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    // ── Travel Style & Interests ──────────────────────────────

    @Enumerated(EnumType.STRING)
    @Column(name = "travel_style", length = 30)
    private TravelStyle travelStyle;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "favorite_categories", columnDefinition = "jsonb")
    private List<String> favoriteCategories;

    @Enumerated(EnumType.STRING)
    @Column(name = "activity_level", length = 20)
    private ActivityLevel activityLevel;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "cuisine_preferences", columnDefinition = "jsonb")
    private List<String> cuisinePreferences;

    // ── Trip Preferences ──────────────────────────────────────

    @Enumerated(EnumType.STRING)
    @Column(name = "preferred_climate", length = 20)
    private PreferredClimate preferredClimate;

    @Enumerated(EnumType.STRING)
    @Column(name = "trip_pace", length = 20)
    private TripPace tripPace;

    @Enumerated(EnumType.STRING)
    @Column(name = "accommodation_type", length = 20)
    private AccommodationType accommodationType;

    @Enumerated(EnumType.STRING)
    @Column(name = "transport_preference", length = 30)
    private TransportPreference transportPreference;

    // ── Constraints & Accessibility ───────────────────────────

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "dietary_restrictions", columnDefinition = "jsonb")
    private List<String> dietaryRestrictions;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "accessibility_needs", columnDefinition = "jsonb")
    private List<String> accessibilityNeeds;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "avoid_categories", columnDefinition = "jsonb")
    private List<String> avoidCategories;

    // ── Budget Details ────────────────────────────────────────

    @Column(name = "daily_budget", precision = 10, scale = 2)
    private BigDecimal dailyBudget;

    @Column(name = "budget_currency", length = 3)
    private String budgetCurrency;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "splurge_categories", columnDefinition = "jsonb")
    private List<String> splurgeCategories;

    // ── Language & Communication ──────────────────────────────

    @Column(name = "preferred_language", length = 5)
    private String preferredLanguage;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "spoken_languages", columnDefinition = "jsonb")
    private List<String> spokenLanguages;

    // ── Timestamps ────────────────────────────────────────────

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    protected void onCreate() {
        Instant now = Instant.now();
        if (this.createdAt == null)
            this.createdAt = now;
        if (this.updatedAt == null)
            this.updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = Instant.now();
    }
}
