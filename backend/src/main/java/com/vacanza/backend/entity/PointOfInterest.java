package com.vacanza.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UuidGenerator;

import java.time.LocalTime;
import java.util.UUID;

@Entity
@Table(
        name = "points_of_interest",
        indexes = {
                // 👇 THIS LINE completes the "Composite Index" requirement
                @Index(name = "idx_poi_location", columnList = "latitude, longitude")
        }
)
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class PointOfInterest {

    @Id
    @GeneratedValue
    @UuidGenerator
    @Column(name = "poi_id", updatable = false, nullable = false)
    private UUID poiId;

    @Column(nullable = false, length = 500)
    private String name;

    @Column(nullable = false)
    private String category;

    @Column(nullable = false)
    private Double latitude;

    @Column(nullable = false)
    private Double longitude;

    // Useful if Foursquare gives opening hours, otherwise nullable
    @Column(name = "start_time",  nullable = true)
    private LocalTime startTime;

    @Column(name = "end_time", nullable = true)
    private LocalTime endTime;

    @Column(name = "custom_duration")
    private Integer customDuration; // Minutes to spend there

    @Column(columnDefinition = "TEXT")
    private String description;

    // OPTIONAL FIELDS
    // These allow nulls because not every place has a rating/price.

    @Column(name = "rating", nullable = true)
    private Double rating;

    @Column(name = "price_level", length = 10, nullable = true)
    private String priceLevel;

    @Column(name = "external_id", unique = true, nullable = true, length = 255)
    private String externalId; // Foursquare ID (Optional for user-created places)

}
