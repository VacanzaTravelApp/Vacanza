package com.vacanza.backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.UuidGenerator;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "ingested_tiles",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_tile_zoom_category",
                columnNames = {"tile_x", "tile_y", "zoom_level", "category"}),
        indexes = @Index(
                name = "idx_tile_range",
                columnList = "zoom_level, tile_x, tile_y, category"))
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class IngestedTile {

    @Id
    @GeneratedValue
    @UuidGenerator
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    @Column(name = "tile_x", nullable = false)
    private Integer tileX;

    @Column(name = "tile_y", nullable = false)
    private Integer tileY;

    @Column(name = "zoom_level", nullable = false)
    private Integer zoomLevel;

    @Column(nullable = false, length = 50)
    private String category;

    @Column(name = "ingested_at", nullable = false)
    private Instant ingestedAt;
}
