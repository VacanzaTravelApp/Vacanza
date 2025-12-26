package com.vacanza.backend.service;

import com.vacanza.backend.dto.request.PoiSearchInAreaRequestDTO;
import com.vacanza.backend.dto.response.PoiSearchInAreaResponseDTO;
import com.vacanza.backend.entity.PointOfInterest;
import com.vacanza.backend.repo.PointOfInterestRepository;
import com.vacanza.backend.service.impl.PoiSearchImpl;
import com.vacanza.backend.validation.PoiAreaRequestValidator;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@AllArgsConstructor
public class PoiSearchService implements PoiSearchImpl {

    // ===== Defaults & Guards =====
    private static final int DEFAULT_PAGE = 0;
    private static final int DEFAULT_LIMIT = 200;
    private static final int MAX_RESULT_COUNT = 5000;
    private static final double MAX_BBOX_AREA = 25.0; // MVP abuse guard

    private final PointOfInterestRepository poiRepository;
    private final PoiAreaRequestValidator validator;

    @Override
    public PoiSearchInAreaResponseDTO searchInArea(PoiSearchInAreaRequestDTO request) {

        // 1) Validate request (structure + limits)
        validator.validate(request);

        // 2) Apply defaults
        int page = request.getPage() != null ? request.getPage() : DEFAULT_PAGE;
        int limit = request.getLimit() != null ? request.getLimit() : DEFAULT_LIMIT;

        // 3) Normalize categories (case-insensitive filter)
        List<String> normalizedCategories =
                (request.getCategories() == null) ? List.of()
                        : request.getCategories().stream()
                        .map(PoiSearchService::normalizeCategory)
                        .filter(c -> c != null && !c.isBlank())
                        .distinct()
                        .toList();

        // 4) Resolve bbox (BBOX directly, POLYGON -> bboxFromPolygon)
        PoiSearchInAreaRequestDTO.Bbox bbox = resolveBbox(request);

        // 5) Abuse guard: bbox size
        guardBboxSize(bbox);

        // 6) Fetch candidates by bbox (DB-side)
        List<PointOfInterest> candidates = fetchByBbox(bbox, normalizedCategories);

        // 7) If POLYGON, filter bbox-candidates with point-in-polygon (service-level)
        if (request.getSelectionType() == PoiSearchInAreaRequestDTO.SelectionType.POLYGON) {
            List<PoiSearchInAreaRequestDTO.LatLng> polygon = request.getPolygon();
            candidates = candidates.stream()
                    .filter(p -> pointInPolygon(p.getLatitude(), p.getLongitude(), polygon))
                    .toList();
        }

        // 8) Abuse guard: result count
        if (candidates.size() > MAX_RESULT_COUNT) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "TOO_MANY_RESULTS");
        }

        // 9) Sorting
        PoiSearchInAreaRequestDTO.SortType sortType =
                request.getSort() != null ? request.getSort() : PoiSearchInAreaRequestDTO.SortType.RATING_DESC;

        if (sortType == PoiSearchInAreaRequestDTO.SortType.DISTANCE_TO_CENTER) {
            sortByDistanceToBboxCenter(candidates, bbox);
        } else {
            // null-safe rating sort desc (in-place)
            candidates.sort(
                    Comparator.comparing(
                            PointOfInterest::getRating,
                            Comparator.nullsLast(Double::compareTo)
                    ).reversed()
            );
        }

        // 10) countsByCategory should be calculated from TOTAL results (before pagination)
        Map<String, Integer> countsByCategory = candidates.stream()
                .collect(Collectors.groupingBy(
                        p -> normalizeCategory(p.getCategory()),
                        Collectors.summingInt(x -> 1)
                ));

        // 11) Pagination
        int from = Math.min(page * limit, candidates.size());
        int to = Math.min(from + limit, candidates.size());
        List<PointOfInterest> pageItems = candidates.subList(from, to);

        // 12) Map entity → summary DTO
        List<PoiSearchInAreaResponseDTO.PoiSummaryDTO> summaries =
                pageItems.stream().map(this::toSummary).toList();

        // 13) Build response
        return PoiSearchInAreaResponseDTO.builder()
                .count(candidates.size())
                .pois(summaries)
                .countsByCategory(countsByCategory)
                .build();
    }

    // ===== Helpers =====

    private PoiSearchInAreaRequestDTO.Bbox resolveBbox(PoiSearchInAreaRequestDTO request) {
        if (request.getSelectionType() == PoiSearchInAreaRequestDTO.SelectionType.BBOX) {
            return request.getBbox();
        }
        return bboxFromPolygon(request.getPolygon());
    }

    private static String normalizeCategory(String s) {
        return (s == null) ? null : s.trim().toLowerCase(java.util.Locale.ROOT);
    }

    private PoiSearchInAreaRequestDTO.Bbox bboxFromPolygon(List<PoiSearchInAreaRequestDTO.LatLng> polygon) {
        double minLat = Double.POSITIVE_INFINITY;
        double minLng = Double.POSITIVE_INFINITY;
        double maxLat = Double.NEGATIVE_INFINITY;
        double maxLng = Double.NEGATIVE_INFINITY;

        for (var p : polygon) {
            minLat = Math.min(minLat, p.getLat());
            minLng = Math.min(minLng, p.getLng());
            maxLat = Math.max(maxLat, p.getLat());
            maxLng = Math.max(maxLng, p.getLng());
        }

        return new PoiSearchInAreaRequestDTO.Bbox(minLat, minLng, maxLat, maxLng);
    }

    private void guardBboxSize(PoiSearchInAreaRequestDTO.Bbox bbox) {
        double area = (bbox.getMaxLat() - bbox.getMinLat()) * (bbox.getMaxLng() - bbox.getMinLng());
        if (area > MAX_BBOX_AREA) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "BBOX_TOO_LARGE");
        }
    }

    private List<PointOfInterest> fetchByBbox(PoiSearchInAreaRequestDTO.Bbox bbox, List<String> categories) {
        if (categories == null || categories.isEmpty()) {
            return poiRepository.findByLatitudeBetweenAndLongitudeBetween(
                    bbox.getMinLat(), bbox.getMaxLat(),
                    bbox.getMinLng(), bbox.getMaxLng()
            );
        }

        return poiRepository.findByLatitudeBetweenAndLongitudeBetweenAndCategoryIn(
                bbox.getMinLat(), bbox.getMaxLat(),
                bbox.getMinLng(), bbox.getMaxLng(),
                categories
        );
    }

    private void sortByDistanceToBboxCenter(List<PointOfInterest> pois, PoiSearchInAreaRequestDTO.Bbox bbox) {
        double centerLat = (bbox.getMinLat() + bbox.getMaxLat()) / 2.0;
        double centerLng = (bbox.getMinLng() + bbox.getMaxLng()) / 2.0;

        pois.sort(Comparator.comparingDouble(
                poi -> squaredDistance(centerLat, centerLng, poi.getLatitude(), poi.getLongitude())
        ));
    }

    private double squaredDistance(double lat1, double lng1, double lat2, double lng2) {
        double dLat = lat1 - lat2;
        double dLng = lng1 - lng2;
        return dLat * dLat + dLng * dLng;
    }

    private PoiSearchInAreaResponseDTO.PoiSummaryDTO toSummary(PointOfInterest poi) {
        return PoiSearchInAreaResponseDTO.PoiSummaryDTO.builder()
                .poiId(poi.getPoiId())
                .name(poi.getName())
                .category(poi.getCategory())
                .latitude(poi.getLatitude())
                .longitude(poi.getLongitude())
                .rating(poi.getRating())
                .priceLevel(poi.getPriceLevel())
                .externalId(poi.getExternalId())
                .build();
    }

    // Ray-casting algorithm (lat=x, lng=y)
    private static boolean pointInPolygon(double lat, double lng, List<PoiSearchInAreaRequestDTO.LatLng> polygon) {
        boolean inside = false;
        for (int i = 0, j = polygon.size() - 1; i < polygon.size(); j = i++) {
            double xi = polygon.get(i).getLat();
            double yi = polygon.get(i).getLng();
            double xj = polygon.get(j).getLat();
            double yj = polygon.get(j).getLng();

            boolean intersect = ((yi > lng) != (yj > lng)) &&
                    (lat < (xj - xi) * (lng - yi) / ((yj - yi) + 0.0) + xi);

            if (intersect) inside = !inside;
        }
        return inside;
    }
}