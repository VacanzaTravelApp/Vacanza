/*package com.vacanza.backend.runner;

import com.vacanza.backend.entity.PointOfInterest;
import com.vacanza.backend.repo.PointOfInterestRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.List;


@Component
@RequiredArgsConstructor
public class SpatialTestRunner implements CommandLineRunner {

    private final PointOfInterestRepository repository;

    @Override
    public void run(String... args) throws Exception {
        // Only run if the database is empty

        repository.deleteAll();
        System.out.println("🧹 CLEANUP: Deleted old test data.");

        if (repository.count() == 0) {
            System.out.println("🌱 SEED: Adding test data...");

            // 1. Place: Ankara (Inside the box)
            PointOfInterest inside = PointOfInterest.builder()
                    .name("Ankara Castle")
                    .category("Historic Site")
                    .latitude(39.94)
                    .longitude(32.86)
                    .externalId("fsq_ankara_123") // Mandatory ID
                    .description("A historic fortification in Ankara.")
                    .build();

            // 2. Place: Istanbul (Outside the box)
            PointOfInterest outside = PointOfInterest.builder()
                    .name("Galata Tower")
                    .category("Monument")
                    .latitude(41.02)
                    .longitude(28.97)
                    .externalId("fsq_istanbul_456") // Mandatory ID
                    .description("A medieval stone tower in Istanbul.")
                    .build();

            repository.saveAll(List.of(inside, outside));
        }
        System.out.println("🔍 TEST: Running BBOX Query...");

        // We draw a box around Ankara (Lat: 39-40, Lon: 32-33)
        List<PointOfInterest> results = repository.findByLatitudeBetweenAndLongitudeBetween(
                39.0, 40.0,  // Min Lat, Max Lat
                32.0, 33.0   // Min Lon, Max Lon
        );

        // PRINT RESULTS
        System.out.println("------------------------------------------------");
        System.out.println("✅ PLACES FOUND: " + results.size());
        results.forEach(poi -> System.out.println("   📍 Found: " + poi.getName()));
        System.out.println("------------------------------------------------");

        // Simple validation logic
        if (results.size() == 1 && results.get(0).getName().equals("Ankara Castle")) {
            System.out.println("🚀 SUCCESS: The database correctly used coordinates to filter results!");
        } else {
            System.out.println("⚠️ FAILURE: Expected 1 place (Ankara), but got " + results.size());
        }
    }
} */
