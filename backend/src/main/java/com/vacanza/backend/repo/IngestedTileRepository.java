package com.vacanza.backend.repo;

import com.vacanza.backend.entity.IngestedTile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface IngestedTileRepository extends JpaRepository<IngestedTile, UUID> {

    boolean existsByTileXAndTileYAndZoomLevelAndCategory(
            Integer tileX, Integer tileY, Integer zoomLevel, String category);

    List<IngestedTile> findByZoomLevelAndTileXBetweenAndTileYBetweenAndCategory(
            Integer zoomLevel,
            Integer minTileX, Integer maxTileX,
            Integer minTileY, Integer maxTileY,
            String category);
}
