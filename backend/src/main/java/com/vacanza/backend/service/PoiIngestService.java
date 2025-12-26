package com.vacanza.backend.service;

import com.vacanza.backend.entity.PointOfInterest;
import com.vacanza.backend.integration.GeoapifyClient;
import com.vacanza.backend.integration.GeoapifyResponse;
import com.vacanza.backend.repo.PointOfInterestRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PoiIngestService {

    private final GeoapifyClient geoapifyClient;
    private final PointOfInterestRepository poiRepository;

    // 🔥 MULTI CATEGORY INGEST
    @Transactional
    public int ingestMultipleCategories(
            String filter,
            List<String> frontendCategories,
            int limit
    ) {

        int totalSaved = 0;

        for (String frontendCategory : frontendCategories) {

            String geoapifyCategory =
                    mapFrontendToGeoapify(frontendCategory);

            if (geoapifyCategory == null) continue;

            totalSaved += ingestSingleCategory(
                    filter,
                    geoapifyCategory,
                    frontendCategory,
                    limit
            );
        }

        return totalSaved;
    }

    // 🔥 TEK CATEGORY INGEST
    private int ingestSingleCategory(
            String filter,
            String geoapifyCategory,
            String internalCategory,
            int limit
    ) {

        GeoapifyResponse resp = geoapifyClient
                .search(filter, List.of(geoapifyCategory), limit)
                .block();

        if (resp == null || resp.getFeatures() == null) return 0;

        int saved = 0;

        for (GeoapifyResponse.Feature f : resp.getFeatures()) {

            if (f.getProperties() == null || f.getGeometry() == null) continue;

            String externalId = f.getProperties().getPlace_id();
            if (externalId == null || poiRepository.existsByExternalId(externalId)) continue;

            var coords = f.getGeometry().getCoordinates();
            if (coords == null || coords.size() < 2) continue;

            PointOfInterest poi = new PointOfInterest();
            poi.setExternalId(externalId);
            poi.setName(
                    f.getProperties().getName() != null
                            ? f.getProperties().getName()
                            : "Unnamed"
            );
            poi.setLatitude(coords.get(1));
            poi.setLongitude(coords.get(0));
            poi.setCategory(internalCategory);
            poi.setRating(f.getProperties().getRating());
            poi.setPriceLevel(f.getProperties().getPrice_level());

            poiRepository.save(poi);
            saved++;
        }

        return saved;
    }

    // FRONTEND → GEOAPIFY MAP
    private String mapFrontendToGeoapify(String c) {
        return switch (c.toLowerCase()) {
            case "restaurant" -> "catering.restaurant";
            case "cafe" -> "catering.cafe";
            case "museum" -> "entertainment.museum";
            case "monuments" -> "tourism.attraction";
            case "parks" -> "leisure.park";
            default -> null;
        };
    }
}
