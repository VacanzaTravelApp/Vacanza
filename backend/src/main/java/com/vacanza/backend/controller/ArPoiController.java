package com.vacanza.backend.controller;

import com.vacanza.backend.dto.request.PoiSearchInAreaRequestDTO;
import com.vacanza.backend.dto.response.ArNearbyPoiResponseDTO;
import com.vacanza.backend.dto.response.PoiSearchInAreaResponseDTO;
import com.vacanza.backend.service.PoiSearchService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Locale;

@RestController
@RequestMapping("/pois")
@RequiredArgsConstructor
public class ArPoiController {

    private static final double DEFAULT_RADIUS_METERS = 600.0;
    private static final double MAX_RADIUS_METERS = 2000.0;
    private static final int DEFAULT_LIMIT = 40;
    private static final int MAX_LIMIT = 100;

    private final PoiSearchService poiSearchService;

    /**
     * UC1.11: Lightweight nearby POI endpoint for AR mode.
     *
     * Implemented as a thin wrapper around the existing search-in-area
     * flow to avoid duplicating business logic.
     */
    @GetMapping("/nearby")
    public ResponseEntity<List<ArNearbyPoiResponseDTO>> getNearbyPoisForAr(
            @RequestParam("lat") Double lat,
            @RequestParam("lng") Double lng,
            @RequestParam(value = "radiusMeters", required = false) Double radiusMeters,
            @RequestParam(value = "categories", required = false) String categories,
            @RequestParam(value = "limit", required = false) Integer limit
    ) {
        if (lat == null || lng == null) {
            return ResponseEntity.badRequest().body(Collections.emptyList());
        }

        double radius = radiusMeters != null ? radiusMeters : DEFAULT_RADIUS_METERS;
        if (radius <= 0) {
            radius = DEFAULT_RADIUS_METERS;
        } else if (radius > MAX_RADIUS_METERS) {
            radius = MAX_RADIUS_METERS;
        }

        int effectiveLimit = limit != null ? limit : DEFAULT_LIMIT;
        if (effectiveLimit <= 0) {
            effectiveLimit = DEFAULT_LIMIT;
        } else if (effectiveLimit > MAX_LIMIT) {
            effectiveLimit = MAX_LIMIT;
        }

        List<String> categoryList = parseCategories(categories);

        PoiSearchInAreaRequestDTO.Bbox bbox = bboxFromCenter(lat, lng, radius);

        PoiSearchInAreaRequestDTO searchRequest = PoiSearchInAreaRequestDTO.builder()
                .selectionType(PoiSearchInAreaRequestDTO.SelectionType.BBOX)
                .bbox(bbox)
                .categories(categoryList.isEmpty() ? null : categoryList)
                .page(0)
                .limit(effectiveLimit)
                .sort(PoiSearchInAreaRequestDTO.SortType.DISTANCE_TO_CENTER)
                .build();

        PoiSearchInAreaResponseDTO searchResponse = poiSearchService.searchInArea(searchRequest);

        List<ArNearbyPoiResponseDTO> arPois = new ArrayList<>();
        if (searchResponse.getPois() != null) {
            for (PoiSearchInAreaResponseDTO.PoiSummaryDTO p : searchResponse.getPois()) {
                Double plat = p.getLatitude();
                Double plng = p.getLongitude();
                if (plat == null || plng == null) {
                    continue;
                }
                double distance = haversineMeters(lat, lng, plat, plng);
                ArNearbyPoiResponseDTO dto = ArNearbyPoiResponseDTO.builder()
                        .poiId(p.getPoiId())
                        .name(p.getName())
                        .category(p.getCategory())
                        .latitude(plat)
                        .longitude(plng)
                        .distanceMeters(distance)
                        .build();
                arPois.add(dto);
            }
        }

        // Filter out POIs that are actually outside the requested radius
        List<ArNearbyPoiResponseDTO> filtered = new ArrayList<>();
        for (ArNearbyPoiResponseDTO dto : arPois) {
            if (dto.getDistanceMeters() != null && dto.getDistanceMeters() <= radius) {
                filtered.add(dto);
            }
        }

        // Sort by distance ascending
        filtered.sort((a, b) -> Double.compare(
                a.getDistanceMeters() != null ? a.getDistanceMeters() : Double.MAX_VALUE,
                b.getDistanceMeters() != null ? b.getDistanceMeters() : Double.MAX_VALUE
        ));

        // Apply final limit after filtering/sorting
        if (filtered.size() > effectiveLimit) {
            filtered = new ArrayList<>(filtered.subList(0, effectiveLimit));
        }

        return ResponseEntity.ok(filtered);
    }

    private List<String> parseCategories(String categories) {
        if (categories == null || categories.isBlank()) {
            return Collections.emptyList();
        }
        String[] parts = categories.split(",");
        List<String> result = new ArrayList<>();
        for (String raw : parts) {
            if (raw == null) continue;
            String c = raw.trim();
            if (!c.isEmpty()) {
                result.add(c.toLowerCase(Locale.ROOT));
            }
        }
        return result;
    }

    /**
     * Approximate bbox from center point and radius in meters.
     * This reuses the existing bbox-based search flow without introducing
     * new repository queries.
     */
    private PoiSearchInAreaRequestDTO.Bbox bboxFromCenter(double lat, double lng, double radiusMeters) {
        // Approximate conversion: 1 degree latitude ~= 111km
        double latDelta = radiusMeters / 111_000.0;
        double lngDelta = radiusMeters / (111_000.0 * Math.cos(Math.toRadians(lat)));

        double minLat = lat - latDelta;
        double maxLat = lat + latDelta;
        double minLng = lng - lngDelta;
        double maxLng = lng + lngDelta;

        return new PoiSearchInAreaRequestDTO.Bbox(minLat, minLng, maxLat, maxLng);
    }

    /**
     * Haversine distance (meters) between two lat/lng points.
     */
    private double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
        final double R = 6371_000; // Earth radius in meters
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
}

