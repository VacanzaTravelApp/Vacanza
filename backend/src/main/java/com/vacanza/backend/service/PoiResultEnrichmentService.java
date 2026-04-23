package com.vacanza.backend.service;

import com.vacanza.backend.dto.internal.PoiResult;
import com.vacanza.backend.entity.PointOfInterest;
import com.vacanza.backend.repo.PointOfInterestRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

/**
 * Enriches Mapbox {@link PoiResult} rows with {@link PoiCategoryFamily} and optional DB fields.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PoiResultEnrichmentService {

    private static final double PROXIMITY_DELTA_DEG = 0.0025;
    private static final double MAX_NAME_MATCH_METERS = 150.0;

    private final PointOfInterestRepository pointOfInterestRepository;
    private final PoiCategoryFamilyResolver categoryFamilyResolver;

    /**
     * Assigns category family and merges DB metadata when a matching {@link PointOfInterest} exists.
     */
    public List<PoiResult> enrichAll(List<PoiResult> pois) {
        if (pois == null || pois.isEmpty()) {
            return pois;
        }
        for (PoiResult p : pois) {
            categoryFamilyResolver.assignFamily(p);
            mergeFromDatabase(p);
        }
        return pois;
    }

    private void mergeFromDatabase(PoiResult p) {
        Optional<PointOfInterest> match = findMatchingEntity(p);
        match.ifPresent(entity -> {
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
        });
    }

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
            if (e.getName() == null) {
                continue;
            }
            if (!normalizeName(e.getName()).equals(target)) {
                continue;
            }
            double m = haversineMeters(lat, lon, e.getLatitude(), e.getLongitude());
            if (m < bestM && m <= MAX_NAME_MATCH_METERS) {
                bestM = m;
                best = e;
            }
        }
        return Optional.ofNullable(best);
    }

    private static String normalizeName(String s) {
        if (s == null) {
            return "";
        }
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
