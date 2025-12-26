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

        /* Validate request (structure + limits) */
        validator.validate(request);

        /* Apply defaults */
        int page = request.getPage() != null ? request.getPage() : DEFAULT_PAGE;
        int limit = request.getLimit() != null ? request.getLimit() : DEFAULT_LIMIT;

        /* Normalize geometry → BBOX */
        PoiSearchInAreaRequestDTO.Bbox bbox = resolveBbox(request);

        /* Abuse guard: bbox size */
        guardBboxSize(bbox);

        /* Fetch ALL matching POIs (before pagination) */
        List<PointOfInterest> all =
                fetchByBbox(bbox, request.getCategories());

        /* Abuse guard: result count */
        if (all.size() > MAX_RESULT_COUNT) {
            throw new ResponseStatusException(
                    HttpStatus.UNPROCESSABLE_ENTITY,
                    "TOO_MANY_RESULTS"
            );
        }

        /* Sorting */
        PoiSearchInAreaRequestDTO.SortType sortType =
                request.getSort() != null
                        ? request.getSort()
                        : PoiSearchInAreaRequestDTO.SortType.RATING_DESC;

        if (sortType == PoiSearchInAreaRequestDTO.SortType.DISTANCE_TO_CENTER) {
            sortByDistanceToBboxCenter(all, bbox);
        } else {
            all.sort(Comparator.comparingDouble(
                    PointOfInterest::getRating
            ).reversed());
        }

        /*Pagination */
        int from = Math.min(page * limit, all.size());
        int to = Math.min(from + limit, all.size());
        List<PointOfInterest> pageItems = all.subList(from, to);

        /*Map entity → summary DTO */
        List<PoiSearchInAreaResponseDTO.PoiSummaryDTO> summaries =
                pageItems.stream()
                        .map(this::toSummary)
                        .toList();

        Map<String, Integer> counts = all.stream()
                .collect(Collectors.groupingBy(PointOfInterest::getCategory, Collectors.summingInt(x -> 1)));
        /*Build response */
        return PoiSearchInAreaResponseDTO.builder()
                .count(all.size())
                .pois(summaries)
                .countsByCategory(counts) // MVP: optional
                .build();
    }


    // Helpers
    private PoiSearchInAreaRequestDTO.Bbox resolveBbox(PoiSearchInAreaRequestDTO request) {
        if (request.getSelectionType() ==
                PoiSearchInAreaRequestDTO.SelectionType.BBOX) {
            return request.getBbox();
        }
        return bboxFromPolygon(request.getPolygon());
    }

    private PoiSearchInAreaRequestDTO.Bbox bboxFromPolygon(
            List<PoiSearchInAreaRequestDTO.LatLng> polygon
    ) {
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

        return new PoiSearchInAreaRequestDTO.Bbox(
                minLat, minLng, maxLat, maxLng
        );
    }

    private void guardBboxSize(PoiSearchInAreaRequestDTO.Bbox bbox) {
        double area =
                (bbox.getMaxLat() - bbox.getMinLat()) *
                        (bbox.getMaxLng() - bbox.getMinLng());

        if (area > MAX_BBOX_AREA) {
            throw new ResponseStatusException(
                    HttpStatus.UNPROCESSABLE_ENTITY,
                    "BBOX_TOO_LARGE"
            );
        }
    }

    private List<PointOfInterest> fetchByBbox(
            PoiSearchInAreaRequestDTO.Bbox bbox,
            List<String> categories
    ) {
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

    private void sortByDistanceToBboxCenter(
            List<PointOfInterest> pois,
            PoiSearchInAreaRequestDTO.Bbox bbox
    ) {
        double centerLat = (bbox.getMinLat() + bbox.getMaxLat()) / 2.0;
        double centerLng = (bbox.getMinLng() + bbox.getMaxLng()) / 2.0;

        pois.sort(Comparator.comparingDouble(
                poi -> squaredDistance(
                        centerLat, centerLng,
                        poi.getLatitude(), poi.getLongitude()
                )
        ));
    }

    private double squaredDistance(
            double lat1, double lng1,
            double lat2, double lng2
    ) {
        double dLat = lat1 - lat2;
        double dLng = lng1 - lng2;
        return dLat * dLat + dLng * dLng;
    }

    private PoiSearchInAreaResponseDTO.PoiSummaryDTO toSummary(
            PointOfInterest poi
    ) {
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
