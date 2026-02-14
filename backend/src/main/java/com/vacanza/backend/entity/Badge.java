package com.vacanza.backend.entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * Badge definitions — seeded via data.sql.
 * No icon stored; frontend maps badge key to its own icons.
 */
@Entity
@Table(name = "badges")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Badge {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    @Column(name = "badge_key", nullable = false, unique = true, length = 50)
    private String key;

    @Column(name = "title", nullable = false, length = 100)
    private String title;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    /**
     * TOTAL_COUNT — total check-ins regardless of category
     * CATEGORY_COUNT — check-ins in specific POI categories
     * CATEGORY_DIVERSITY — distinct categories checked in
     */
    @Column(name = "criteria_type", nullable = false, length = 30)
    private String criteriaType;

    /**
     * Comma-separated POI categories (e.g. "restaurant,cafe").
     * Null for TOTAL_COUNT and CATEGORY_DIVERSITY criteria.
     */
    @Column(name = "criteria_category", length = 200)
    private String criteriaCategory;

    @Column(name = "criteria_threshold", nullable = false)
    private Integer criteriaThreshold;
}
