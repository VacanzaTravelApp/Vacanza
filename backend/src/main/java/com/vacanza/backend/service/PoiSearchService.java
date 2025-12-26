package com.vacanza.backend.service;

import com.vacanza.backend.dto.request.PoiSearchInAreaRequestDTO;
import com.vacanza.backend.dto.response.PoiSearchInAreaResponseDTO;
import com.vacanza.backend.entity.PointOfInterest;
import com.vacanza.backend.repo.PointOfInterestRepository;
import com.vacanza.backend.validation.PoiAreaRequestValidator;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PoiSearchService {

    private final PointOfInterestRepository poiRepository;
    private final PoiIngestService poiIngestService;
    private final PoiAreaRequestValidator validator;

    private static final int DEFAULT_PAGE = 0;
    private static final int DEFAULT_LIMIT = 200;
    private static final int INGEST_LIMIT = 20;

    public PoiSearchInAreaResponseDTO searchInArea(PoiSearchInAreaRequestDTO request) {

        validator.validate(request);

        int page = request.getPage() != null ? request.getPage() : DEFAULT_PAGE;
        int limit = request.getLimit() != null ? request.getLimit() : DEFAULT_LIMIT;

        PoiSearchInAreaRequestDTO.Bbox bbox = resolveBbox(request);

        List<String> frontendCategories =
                request.getCategories() == null
                        ? List.of()
                        : request.getCategories().stream()
                        .map(String::toLowerCase)
                        .distinct()
                        .toList();

        List<PointOfInterest> all = fetchByBbox(bbox, frontendCategories);

        // 🔥 DB EMPTY → INGEST
        if (all.isEmpty()) {

            String geoapifyFilter = buildRectFilterFromRequest(request);


            poiIngestService.ingestMultipleCategories(
                    geoapifyFilter,
                    frontendCategories,
                    INGEST_LIMIT
            );

            all = fetchByBbox(bbox, frontendCategories);
        }

        // sort
        if (request.getSort() == PoiSearchInAreaRequestDTO.SortType.DISTANCE_TO_CENTER) {
            sortByDistanceToCenter(all, bbox);
        } else {
            all.sort(
                    Comparator.comparing(
                            PointOfInterest::getRating,
                            Comparator.nullsLast(Double::compareTo)
                    ).reversed()
            );
        }

        Map<String, Integer> countsByCategory = all.stream()
                .collect(Collectors.groupingBy(
                        PointOfInterest::getCategory,
                        Collectors.summingInt(x -> 1)
                ));

        int from = Math.min(page * limit, all.size());
        int to = Math.min(from + limit, all.size());

        List<PoiSearchInAreaResponseDTO.PoiSummaryDTO> pois =
                all.subList(from, to).stream()
                        .map(this::toSummary)
                        .toList();

        return PoiSearchInAreaResponseDTO.builder()
                .count(all.size())
                .pois(pois)
                .countsByCategory(countsByCategory)
                .build();
    }

    // ================= HELPERS =================

    private List<PointOfInterest> fetchByBbox(
            PoiSearchInAreaRequestDTO.Bbox b,
            List<String> categories
    ) {
        if (categories.isEmpty()) {
            return poiRepository.findByLatitudeBetweenAndLongitudeBetween(
                    b.getMinLat(), b.getMaxLat(),
                    b.getMinLng(), b.getMaxLng()
            );
        }

        return poiRepository.findByLatitudeBetweenAndLongitudeBetweenAndCategoryIn(
                b.getMinLat(), b.getMaxLat(),
                b.getMinLng(), b.getMaxLng(),
                categories
        );
    }

    private PoiSearchInAreaRequestDTO.Bbox resolveBbox(PoiSearchInAreaRequestDTO r) {
        if (r.getSelectionType() == PoiSearchInAreaRequestDTO.SelectionType.BBOX) {
            return r.getBbox();
        }
        return bboxFromPolygon(r.getPolygon());
    }

    private PoiSearchInAreaRequestDTO.Bbox bboxFromPolygon(
            List<PoiSearchInAreaRequestDTO.LatLng> poly
    ) {
        double minLat = Double.MAX_VALUE, minLng = Double.MAX_VALUE;
        double maxLat = -Double.MAX_VALUE, maxLng = -Double.MAX_VALUE;

        for (var p : poly) {
            minLat = Math.min(minLat, p.getLat());
            minLng = Math.min(minLng, p.getLng());
            maxLat = Math.max(maxLat, p.getLat());
            maxLng = Math.max(maxLng, p.getLng());
        }

        return new PoiSearchInAreaRequestDTO.Bbox(minLat, minLng, maxLat, maxLng);
    }

    private void sortByDistanceToCenter(
            List<PointOfInterest> pois,
            PoiSearchInAreaRequestDTO.Bbox b
    ) {
        double cl = (b.getMinLat() + b.getMaxLat()) / 2;
        double cg = (b.getMinLng() + b.getMaxLng()) / 2;

        pois.sort(Comparator.comparingDouble(
                p -> Math.pow(cl - p.getLatitude(), 2)
                        + Math.pow(cg - p.getLongitude(), 2)
        ));
    }

    private PoiSearchInAreaResponseDTO.PoiSummaryDTO toSummary(PointOfInterest p) {
        return PoiSearchInAreaResponseDTO.PoiSummaryDTO.builder()
                .poiId(p.getPoiId())
                .name(p.getName())
                .category(p.getCategory())
                .latitude(p.getLatitude())
                .longitude(p.getLongitude())
                .rating(p.getRating())
                .priceLevel(p.getPriceLevel())
                .externalId(p.getExternalId())
                .build();
    }

    private String buildGeoapifyFilter(PoiSearchInAreaRequestDTO r) {

        if (r.getSelectionType() == PoiSearchInAreaRequestDTO.SelectionType.BBOX) {
            var b = r.getBbox();
            return String.format(
                    Locale.US,
                    "rect:%f,%f,%f,%f",
                    b.getMinLng(), b.getMinLat(),
                    b.getMaxLng(), b.getMaxLat()
            );
        }

        StringBuilder sb = new StringBuilder("polygon:");
        for (int i = 0; i < r.getPolygon().size(); i++) {
            var p = r.getPolygon().get(i);
            sb.append(p.getLng()).append(" ").append(p.getLat());
            if (i < r.getPolygon().size() - 1) sb.append(",");
        }
        return sb.toString();
    }

    private String buildRectFilterFromRequest(PoiSearchInAreaRequestDTO r) {

        PoiSearchInAreaRequestDTO.Bbox b;

        if (r.getSelectionType() == PoiSearchInAreaRequestDTO.SelectionType.BBOX) {
            b = r.getBbox();
        } else {
            // polygon → bbox
            double minLat = Double.MAX_VALUE, minLng = Double.MAX_VALUE;
            double maxLat = -Double.MAX_VALUE, maxLng = -Double.MAX_VALUE;

            for (var p : r.getPolygon()) {
                minLat = Math.min(minLat, p.getLat());
                minLng = Math.min(minLng, p.getLng());
                maxLat = Math.max(maxLat, p.getLat());
                maxLng = Math.max(maxLng, p.getLng());
            }

            b = new PoiSearchInAreaRequestDTO.Bbox(minLat, minLng, maxLat, maxLng);
        }

        return String.format(
                Locale.US,
                "rect:%f,%f,%f,%f",
                b.getMinLng(), b.getMinLat(),
                b.getMaxLng(), b.getMaxLat()
        );
    }

}
