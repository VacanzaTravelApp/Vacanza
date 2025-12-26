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

    /**
     * Hard guard to avoid huge result sets / abuse.
     * If you expect more, raise carefully or add better paging.
     */
    private static final int MAX_RESULT_COUNT = 5000;

    /**
     * DB query guard (viewport / user-selection should be small).
     * area = (maxLat-minLat) * (maxLng-minLng)
     */
    private static final double MAX_BBOX_AREA = 25.0;

    /**
     * Ingest guard can be larger than DB guard for debugging / initial seed,
     * but still capped to avoid accidentally pulling the entire world.
     * Tune this after MVP.
     */
    private static final double MAX_INGEST_BBOX_AREA = 400.0;

    private final PointOfInterestRepository poiRepository;
    private final PoiAreaRequestValidator validator;
    private final PoiIngestService poiIngestService;

    @Override
    public PoiSearchInAreaResponseDTO searchInArea(PoiSearchInAreaRequestDTO request) {

        // 1) Validate request (structure + limits)
        validator.validate(request);

        // 2) Apply defaults
        int page = request.getPage() != null ? request.getPage() : DEFAULT_PAGE;
        int limit = request.getLimit() != null ? request.getLimit() : DEFAULT_LIMIT;

        // 3) Resolve selection -> bbox
        PoiSearchInAreaRequestDTO.Bbox bbox = resolveBbox(request);

        // 4) DB abuse guard (small viewport expected)
        guardBboxSize(bbox);

        // 5) Normalize categories for case-insensitive filter
        List<String> normalizedCategories =
                (request.getCategories() == null) ? List.of()
                        : request.getCategories().stream()
                        .map(PoiSearchService::normalizeCategory)
                        .filter(c -> c != null && !c.isBlank())
                        .distinct()
                        .toList();

        // 6) Fetch ALL matching POIs (before pagination)
        List<PointOfInterest> all = fetchByBbox(bbox, normalizedCategories);

        // 7) If DB is empty for this area: ingest from Foursquare once, persist, then re-query DB
        // NOTE: Ingest uses a separate guard to allow slightly bigger areas during seeding/debug.
        if (all.isEmpty()) {
            guardIngestBboxSize(bbox);

            poiIngestService.ingestFromFoursquareBbox(
                    bbox.getMinLat(), bbox.getMinLng(),
                    bbox.getMaxLat(), bbox.getMaxLng()
            );

            all = fetchByBbox(bbox, normalizedCategories);
        }

        // 8) Guard: too many results even after DB filtering
        if (all.size() > MAX_RESULT_COUNT) {
            throw new ResponseStatusException(
                    HttpStatus.UNPROCESSABLE_ENTITY,
                    "TOO_MANY_RESULTS"
            );
        }

        // 9) Sorting (null-safe)
        PoiSearchInAreaRequestDTO.SortType sortType =
                request.getSort() != null
                        ? request.getSort()
                        : PoiSearchInAreaRequestDTO.SortType.RATING_DESC;

        if (sortType == PoiSearchInAreaRequestDTO.SortType.DISTANCE_TO_CENTER) {
            sortByDistanceToBboxCenter(all, bbox);
        } else {
            all.sort(Comparator.comparing(
                    PointOfInterest::getRating,
                    Comparator.nullsLast(Double::compareTo)
            ).reversed());
        }

        // 10) countsByCategory should be calculated from TOTAL results (before pagination)
        // (UI filter panel typically needs full counts)
        Map<String, Integer> countsByCategory = all.stream()
                .collect(Collectors.groupingBy(
                        p -> normalizeCategory(p.getCategory()),
                        Collectors.summingInt(x -> 1)
                ));

        // 11) Pagination
        int from = Math.min(page * limit, all.size());
        int to = Math.min(from + limit, all.size());
        List<PointOfInterest> pageItems = all.subList(from, to);

        // 12) Map entity -> summary DTO
        List<PoiSearchInAreaResponseDTO.PoiSummaryDTO> summaries =
                pageItems.stream()
                        .map(this::toSummary)
                        .toList();

        // 13) Build response
        return PoiSearchInAreaResponseDTO.builder()
                .count(all.size())
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

    private void guardIngestBboxSize(PoiSearchInAreaRequestDTO.Bbox bbox) {
        double area = (bbox.getMaxLat() - bbox.getMinLat()) * (bbox.getMaxLng() - bbox.getMinLng());
        if (area > MAX_INGEST_BBOX_AREA) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "INGEST_BBOX_TOO_LARGE");
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
}