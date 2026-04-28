package com.vacanza.backend.service;

import com.vacanza.backend.dto.internal.PoiResult;
import com.vacanza.backend.entity.PointOfInterest;
import com.vacanza.backend.integration.FoursquareClient;
import com.vacanza.backend.integration.FoursquareResponse;
import com.vacanza.backend.integration.MapboxPoiSearchClient;
import com.vacanza.backend.repo.PointOfInterestRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalTime;
import java.util.Collection;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * Seeds the {@link PointOfInterest} table with POI data from Mapbox Search Box
 * and enriches each entry with Foursquare Place Details (rating, hours, price).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PoiIngestService {

    private final MapboxPoiSearchClient mapboxPoiSearchClient;
    private final FoursquareClient foursquareClient;
    private final PointOfInterestRepository poiRepository;

    /** Frontend category key → Mapbox Search Box category (MapboxPoiSearchClient.CATEGORY_MAP compatible). */
    private static final Map<String, String> FRONTEND_TO_MAPBOX = Map.of(
            "restaurant", "restaurant",
            "cafe", "cafe",
            "museum", "museum",
            "monuments", "monument",
            "parks", "park"
    );

    @Transactional
    public int ingestMultipleCategories(
            double minLon, double minLat,
            double maxLon, double maxLat,
            List<String> frontendCategories,
            int limit) {

        int totalSaved = 0;

        for (String frontendCategory : frontendCategories) {
            String mapboxCategory = FRONTEND_TO_MAPBOX.get(frontendCategory.toLowerCase(Locale.ROOT));
            if (mapboxCategory == null) continue;

            totalSaved += ingestSingleCategory(
                    minLon, minLat, maxLon, maxLat,
                    mapboxCategory, frontendCategory, limit);
        }

        return totalSaved;
    }

    /**
     * Persists Mapbox search results after area/stream search completes.
     * Skips rows without a stable {@code externalId} / {@code mapboxId}, and skips existing {@code external_id}.
     */
    @Transactional
    public int ingestFromMapboxResults(Collection<PoiResult> results) {
        if (results == null || results.isEmpty()) {
            return 0;
        }
        int saved = 0;
        for (PoiResult r : results) {
            if (r == null || r.getName() == null || r.getName().isBlank()) {
                continue;
            }

            String externalId = r.getExternalId();
            if (externalId == null || externalId.isBlank()) {
                externalId = r.getMapboxId();
            }
            if (externalId == null || externalId.isBlank()) {
                continue;
            }

            if (poiRepository.existsByExternalId(externalId)) {
                continue;
            }

            PointOfInterest poi = new PointOfInterest();
            poi.setExternalId(externalId);
            poi.setName(r.getName().trim());
            poi.setLatitude(r.getLat());
            poi.setLongitude(r.getLon());
            String cat = r.getCategory();
            poi.setCategory(cat != null && !cat.isBlank() ? cat.toLowerCase(Locale.ROOT) : "others");

            String fsqId = r.getExternalId();
            if (fsqId != null && !fsqId.isBlank()) {
                enrichFromFoursquare(poi, fsqId);
            }

            try {
                poiRepository.save(poi);
                saved++;
            } catch (DataIntegrityViolationException e) {
                log.debug("[POI-INGEST] mapbox batch duplicate skipped: {}", externalId);
            }
        }
        if (saved > 0) {
            log.info("[POI-INGEST] mapbox batch persisted {} new row(s), scanned {}", saved, results.size());
        }
        return saved;
    }

    private int ingestSingleCategory(
            double minLon, double minLat,
            double maxLon, double maxLat,
            String mapboxCategory,
            String internalCategory,
            int limit) {

        List<PoiResult> results = mapboxPoiSearchClient
                .searchByCategory(mapboxCategory, minLon, minLat, maxLon, maxLat)
                .block();

        if (results == null || results.isEmpty()) return 0;

        int saved = 0;

        for (PoiResult r : results) {
            if (saved >= limit) break;

            String externalId = r.getExternalId(); // Foursquare ID from Mapbox
            if (externalId == null || externalId.isBlank()) {
                // Fallback: use mapboxId if no Foursquare ID
                externalId = r.getMapboxId();
            }
            if (externalId == null || poiRepository.existsByExternalId(externalId)) continue;

            PointOfInterest poi = new PointOfInterest();
            poi.setExternalId(externalId);
            poi.setName(r.getName() != null ? r.getName() : "Unnamed");
            poi.setLatitude(r.getLat());
            poi.setLongitude(r.getLon());
            poi.setCategory(internalCategory);

            // Enrich from Foursquare if we have a Foursquare ID
            String fsqId = r.getExternalId();
            if (fsqId != null && !fsqId.isBlank()) {
                enrichFromFoursquare(poi, fsqId);
            }

            try {
                poiRepository.save(poi);
                saved++;
            } catch (DataIntegrityViolationException e) {
                // Race: another request may have inserted same external_id; skip
                log.debug("[POI-INGEST] Duplicate external_id skipped: {}", externalId);
            }
        }

        log.info("[POI-INGEST] category={} saved={} total_results={}", internalCategory, saved, results.size());
        return saved;
    }

    /**
     * Calls Foursquare Place Details to enrich a POI entity with rating, price, and opening hours.
     * Failures are silently logged — a POI without enrichment is still useful.
     */
    private void enrichFromFoursquare(PointOfInterest poi, String fsqId) {
        try {
            FoursquareResponse.Place detail = foursquareClient.getPlaceDetails(fsqId).block();
            if (detail == null) return;

            if (detail.getRating() != null) {
                poi.setRating(detail.getRating());
            }

            if (detail.getPrice() != null) {
                poi.setPriceLevel(mapFoursquarePrice(detail.getPrice()));
            }

            if (detail.getHours() != null && detail.getHours().getRegular() != null) {
                parseOpeningHours(poi, detail.getHours().getRegular());
            }
        } catch (Exception e) {
            log.debug("[POI-INGEST] Foursquare enrichment failed for {}: {}", fsqId, e.getMessage());
        }
    }

    /** Map Foursquare 1-4 price tier to display string. */
    private static String mapFoursquarePrice(int price) {
        return switch (price) {
            case 1 -> "$";
            case 2 -> "$$";
            case 3 -> "$$$";
            case 4 -> "$$$$";
            default -> null;
        };
    }

    /** Extract earliest open and latest close from Foursquare regular hours. */
    private static void parseOpeningHours(PointOfInterest poi, List<FoursquareResponse.Regular> regular) {
        if (regular.isEmpty()) return;

        // Use the first entry as a representative sample
        FoursquareResponse.Regular first = regular.get(0);
        try {
            if (first.getOpen() != null) {
                poi.setStartTime(LocalTime.parse(first.getOpen().substring(0, 2) + ":" + first.getOpen().substring(2)));
            }
            if (first.getClose() != null) {
                poi.setEndTime(LocalTime.parse(first.getClose().substring(0, 2) + ":" + first.getClose().substring(2)));
            }
        } catch (Exception e) {
            // Malformed time string — skip silently
        }
    }
}
