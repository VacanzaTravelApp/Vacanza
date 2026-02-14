package com.vacanza.backend.entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * Level definitions — seeded via data.sql.
 * Maps XP thresholds to level numbers and titles.
 */
@Entity
@Table(name = "level_definitions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LevelDefinition {

    @Id
    @Column(name = "level", nullable = false)
    private Integer level;

    @Column(name = "min_xp", nullable = false)
    private Integer minXp;

    @Column(name = "title", nullable = false, length = 50)
    private String title;
}
