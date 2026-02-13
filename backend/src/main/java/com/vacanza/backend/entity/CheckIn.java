package com.vacanza.backend.entity;

import com.vacanza.backend.entity.enums.CheckInSource;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "check_ins", uniqueConstraints = {
        @UniqueConstraint(name = "uk_checkin_user_poi", columnNames = { "user_id", "poi_id" })
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CheckIn {

    @Id
    @GeneratedValue
    @UuidGenerator
    @Column(name = "check_in_id", nullable = false, updatable = false)
    private UUID checkInId;

    // FK: users.user_id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    // FK: points_of_interest.poi_id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "poi_id", nullable = false)
    private PointOfInterest pointOfInterest;

    @Column(name = "checked_in_at", nullable = false)
    private Instant checkedInAt;

    @Enumerated(EnumType.STRING)
    @Column(name = "source", nullable = false, length = 20)
    private CheckInSource source;

    @PrePersist
    protected void onCreate() {
        if (this.checkedInAt == null) {
            this.checkedInAt = Instant.now();
        }
        if (this.source == null) {
            this.source = CheckInSource.AUTO;
        }
    }
}
