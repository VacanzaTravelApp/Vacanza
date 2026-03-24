package com.vacanza.backend.service;

import com.vacanza.backend.dto.internal.PoiCategoryFamily;
import com.vacanza.backend.dto.internal.PoiResult;
import com.vacanza.backend.entity.PointOfInterest;
import com.vacanza.backend.integration.FoursquareCategoryMapper;
import com.vacanza.backend.integration.FoursquareClient;
import com.vacanza.backend.integration.FoursquareClient.FoursquarePlaceDetail;
import com.vacanza.backend.integration.FoursquareClient.RegularHour;
import com.vacanza.backend.repo.PointOfInterestRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

/**
 * Enriches Mapbox {@link PoiResult} rows with {@link PoiCategoryFamily} and optional DB fields.
 *
 * <p><b>Enrichment strategy (cache-first):</b>
 * <ol>
 *   <li>Assign category family from search category + Mapbox poi_category_ids.</li>
 *   <li>Try to find a matching {@link PointOfInterest} in the DB.</li>
 *   <li>If DB hit → merge fields (rating, price, hours) from DB.</li>
 *   <li>If DB miss AND POI has a Foursquare external ID → call Foursquare API,
 *       write result to DB, then merge fields.</li>
 * </ol>
 * <p>Foursquare is only called once per unique venue. Subsequent lookups for the
 * same place are always served from the local DB (zero API cost).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PoiResultEnrichmentService {

    private static final double PROXIMITY_DELTA_DEG = 0.0025;
    private static final double MAX_NAME_MATCH_METERS = 150.0;
    /** "HHmm" → LocalTime parser for Foursquare regular hours. */
    private static final DateTimeFormatter FSQ_TIME = DateTimeFormatter.ofPattern("HHmm");

    private final PointOfInterestRepository pointOfInterestRepository;
    private final PoiCategoryFamilyResolver categoryFamilyResolver;
    private final FoursquareClient foursquareClient;
    private final FoursquareCategoryMapper foursquareCategoryMapper;

    /**
     * Assigns category family and merges DB/Foursquare metadata for all POIs.
     */
    @Transactional
    public List<PoiResult> enrichAll(List<PoiResult> pois) {
        if (pois == null || pois.isEmpty()) {
            return pois;
        }
        for (PoiResult p : pois) {
            categoryFamilyResolver.assignFamily(p);
            mergeFromDatabaseOrFoursquare(p);
        }
        return pois;
    }

    // ─── Core enrichment logic ────────────────────────────────────────────────

    private void mergeFromDatabaseOrFoursquare(PoiResult p) {
        Optional<PointOfInterest> dbMatch = findMatchingEntity(p);

        if (dbMatch.isPresent()) {
            mergeFromEntity(p, dbMatch.get());
            return;
        }

        // DB miss — try Foursquare if we have a Foursquare ID
        String fsqId = extractFoursquareId(p);
        if (fsqId == null) {
            return;
        }

        FoursquarePlaceDetail detail = foursquareClient
                .getPlaceDetail(fsqId)
                .block(); // synchronous; enrichment is already a blocking operation

        if (detail == null) {
            log.debug("[ENRICHMENT] Foursquare returned no data for fsqId={}", fsqId);
            return;
        }

        PointOfInterest saved = persistFromFoursquare(p, fsqId, detail);
        mergeFromEntity(p, saved);
        refineCategoryFromFoursquare(p, detail);
        log.info("[ENRICHMENT] Persisted Foursquare data for '{}' (fsqId={})", p.getName(), fsqId);
    }

    // ─── Merge from DB entity ─────────────────────────────────────────────────

    private void mergeFromEntity(PoiResult p, PointOfInterest entity) {
        if (p.getRating() == null && entity.getRating() != null) {
            p.setRating(entity.getRating());
        }
        if (p.getPriceLevel() == null && entity.getPriceLevel() != null) {
            p.setPriceLevel(entity.getPriceLevel());
        }
        if (p.getEstimatedDurationMin() == null && entity.getCustomDuration() != null) {
            p.setEstimatedDurationMin(entity.getCustomDuration());
        }
        boolean hours = false;
        if (entity.getStartTime() != null) {
            p.setStartTimeLocal(entity.getStartTime().toString());
            hours = true;
        }
        if (entity.getEndTime() != null) {
            p.setEndTimeLocal(entity.getEndTime().toString());
            hours = true;
        }
        if (hours) {
            p.setOpeningHoursUnknown(false);
        }
    }

    // ─── Foursquare → DB persistence ─────────────────────────────────────────

    @Transactional
    protected PointOfInterest persistFromFoursquare(PoiResult p, String fsqId,
                                                     FoursquarePlaceDetail detail) {
        String subcategory = foursquareCategoryMapper.resolveSubcategory(detail.getCategories());
        String cuisineLabel = foursquareCategoryMapper.resolveCuisineLabel(detail.getCategories());

        // Convert Foursquare 0-10 rating → 0-5 scale our DB uses
        Double rating = detail.getRating() != null ? detail.getRating() / 2.0 : null;

        // Price: Foursquare 1-4 → our "$" / "$$" / "$$$" / "$$$$"
        String priceLevel = detail.getPrice() != null ? "$".repeat(detail.getPrice()) : null;

        // Derive opening hours from the first regular entry (usually Mon representative)
        LocalTime openTime = null;
        LocalTime closeTime = null;
        if (detail.getHours() != null && detail.getHours().getRegular() != null) {
            Optional<RegularHour> sample = detail.getHours().getRegular().stream().findFirst();
            if (sample.isPresent()) {
                openTime = parseTime(sample.get().getOpen());
                closeTime = parseTime(sample.get().getClose());
            }
        }

        PointOfInterest entity = PointOfInterest.builder()
                .name(p.getName())
                .category(subcategory != null ? subcategory : p.getCategory())
                .latitude(p.getLat())
                .longitude(p.getLon())
                .externalId(fsqId)
                .rating(rating)
                .priceLevel(priceLevel)
                .startTime(openTime)
                .endTime(closeTime)
                .description(detail.getDescription())
                .cuisineType(cuisineLabel)
                .build();

        return pointOfInterestRepository.save(entity);
    }

    /** Refine PoiResult's category family using Foursquare data (more precise than Mapbox). */
    private void refineCategoryFromFoursquare(PoiResult p, FoursquarePlaceDetail detail) {
        PoiCategoryFamily family = foursquareCategoryMapper.resolveFamily(detail.getCategories());
        if (family != null) {
            p.setCategoryFamily(family);
        }
        String sub = foursquareCategoryMapper.resolveSubcategory(detail.getCategories());
        if (sub != null) {
            p.setCategory(sub);
        }
    }

    // ─── DB lookup helpers ────────────────────────────────────────────────────

    private Optional<PointOfInterest> findMatchingEntity(PoiResult p) {
        Map<String, String> ext = p.getExternalIds();
        if (ext != null) {
            String fs = ext.get("foursquare");
            if (fs != null && !fs.isBlank()) {
                Optional<PointOfInterest> byFs = pointOfInterestRepository.findByExternalId(fs);
                if (byFs.isPresent()) {
                    return byFs;
                }
            }
        }
        if (p.getExternalId() != null && !p.getExternalId().isBlank()) {
            Optional<PointOfInterest> byExt = pointOfInterestRepository.findByExternalId(p.getExternalId());
            if (byExt.isPresent()) {
                return byExt;
            }
        }
        return findByProximityAndName(p);
    }

    private Optional<PointOfInterest> findByProximityAndName(PoiResult p) {
        double lat = p.getLat();
        double lon = p.getLon();
        List<PointOfInterest> candidates = pointOfInterestRepository.findByLatitudeBetweenAndLongitudeBetween(
                lat - PROXIMITY_DELTA_DEG,
                lat + PROXIMITY_DELTA_DEG,
                lon - PROXIMITY_DELTA_DEG,
                lon + PROXIMITY_DELTA_DEG);
        if (candidates.isEmpty()) {
            return Optional.empty();
        }
        String target = normalizeName(p.getName());
        if (target.isEmpty()) {
            return Optional.empty();
        }
        PointOfInterest best = null;
        double bestM = Double.MAX_VALUE;
        for (PointOfInterest e : candidates) {
            if (e.getName() == null) continue;
            if (!normalizeName(e.getName()).equals(target)) continue;
            double m = haversineMeters(lat, lon, e.getLatitude(), e.getLongitude());
            if (m < bestM && m <= MAX_NAME_MATCH_METERS) {
                bestM = m;
                best = e;
            }
        }
        return Optional.ofNullable(best);
    }

    private static String extractFoursquareId(PoiResult p) {
        Map<String, String> ext = p.getExternalIds();
        if (ext != null) {
            String fs = ext.get("foursquare");
            if (fs != null && !fs.isBlank()) return fs.trim();
        }
        if (p.getExternalId() != null && !p.getExternalId().isBlank()) {
            return p.getExternalId().trim();
        }
        return null;
    }

    // ─── Utilities ────────────────────────────────────────────────────────────

    private static LocalTime parseTime(String hhmm) {
        if (hhmm == null || hhmm.length() != 4) return null;
        try {
            return LocalTime.parse(hhmm, FSQ_TIME);
        } catch (Exception e) {
            return null;
        }
    }

    private static String normalizeName(String s) {
        if (s == null) return "";
        return s.toLowerCase(Locale.ROOT).replace('\u2019', '\'').trim().replaceAll("\\s+", " ");
    }

    private static double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
        final double R = 6_371_000;
        double p1 = Math.toRadians(lat1);
        double p2 = Math.toRadians(lat2);
        double dp = Math.toRadians(lat2 - lat1);
        double dl = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dp / 2) * Math.sin(dp / 2)
                + Math.cos(p1) * Math.cos(p2) * Math.sin(dl / 2) * Math.sin(dl / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
}
