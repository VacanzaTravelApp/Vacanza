package com.vacanza.backend.service;

import com.vacanza.backend.entity.PointOfInterest;
import com.vacanza.backend.integration.FoursquarePlacesClient;
import com.vacanza.backend.integration.FsqPlacesSearchResponse;
import com.vacanza.backend.repo.PointOfInterestRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Locale;

@Service
@RequiredArgsConstructor
public class PoiIngestService {

    private final FoursquarePlacesClient foursquareClient;
    private final PointOfInterestRepository poiRepository;

    public int ingestFromFoursquareBbox(double minLat, double minLng, double maxLat, double maxLng) {
        FsqPlacesSearchResponse resp = foursquareClient.searchByBbox(minLat, minLng, maxLat, maxLng, 50);
        if (resp == null || resp.getResults() == null) return 0;

        int saved = 0;

        for (var p : resp.getResults()) {
            if (p.getFsqId() == null) continue;
            if (p.getGeocodes() == null || p.getGeocodes().getMain() == null) continue;
            if (p.getGeocodes().getMain().getLatitude() == null || p.getGeocodes().getMain().getLongitude() == null) continue;

            String categoryName = null;
            if (p.getCategories() != null && !p.getCategories().isEmpty() && p.getCategories().get(0) != null) {
                categoryName = p.getCategories().get(0).getName();
                if (categoryName != null) categoryName = categoryName.trim().toLowerCase(Locale.ROOT);
            }
            if (categoryName == null || categoryName.isBlank()) categoryName = "unknown";

            PointOfInterest entity = poiRepository.findByExternalId(p.getFsqId())
                    .orElseGet(PointOfInterest::new);

            entity.setExternalId(p.getFsqId());
            entity.setName(p.getName() != null ? p.getName() : "Unnamed");
            entity.setCategory(categoryName);
            entity.setLatitude(p.getGeocodes().getMain().getLatitude());
            entity.setLongitude(p.getGeocodes().getMain().getLongitude());

            // optional mappings
            entity.setRating(p.getRating());
            if (p.getPrice() != null) entity.setPriceLevel(String.valueOf(p.getPrice()));

            poiRepository.save(entity);
            saved++;
        }

        return saved;
    }
}