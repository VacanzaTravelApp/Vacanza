package com.vacanza.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(
        name = "trip_calendar_events",
        uniqueConstraints = @UniqueConstraint(
                name = "uk_trip_calendar_user_route_date",
                columnNames = {"user_id", "route_id", "event_date"}
        )
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TripCalendarEvent {

    @Id
    @GeneratedValue
    @UuidGenerator
    @Column(name = "event_id", nullable = false, updatable = false)
    private UUID eventId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "route_id", nullable = false)
    private AiRoute aiRoute;

    @Column(name = "event_date", nullable = false)
    private LocalDate eventDate;

    /**
     * 1-based itinerary day within the route (Day 1 = start of trip on {@link #eventDate}).
     * Nullable for legacy rows; treated as 1 when null.
     */
    @Column(name = "itinerary_day")
    private Integer itineraryDay;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    protected void onCreate() {
        if (this.createdAt == null) {
            this.createdAt = Instant.now();
        }
    }
}
