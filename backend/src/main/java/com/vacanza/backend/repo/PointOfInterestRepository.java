package com.vacanza.backend.repo;

import com.vacanza.backend.entity.PointOfInterest;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PointOfInterestRepository extends JpaRepository<PointOfInterest, UUID> {

    Optional<PointOfInterest> findByExternalId(String externalId);

    // BBOX: kategori filtresi yoksa kullanılır
    List<PointOfInterest> findByLatitudeBetweenAndLongitudeBetween(
            Double minLat, Double maxLat,
            Double minLon, Double maxLon
    );

    // BBOX + categories: kategori filtresi varsa kullanılır
    List<PointOfInterest> findByLatitudeBetweenAndLongitudeBetweenAndCategoryIn(
            Double minLat, Double maxLat,
            Double minLon, Double maxLon,
            List<String> categories
    );
}