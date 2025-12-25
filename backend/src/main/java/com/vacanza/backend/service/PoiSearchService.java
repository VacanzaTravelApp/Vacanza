package com.vacanza.backend.service;

import com.vacanza.backend.dto.request.PoiSearchInAreaRequestDTO;
import com.vacanza.backend.dto.response.PoiSearchInAreaResponseDTO;
import com.vacanza.backend.entity.PointOfInterest;
import com.vacanza.backend.repo.PointOfInterestRepository;
import com.vacanza.backend.validation.PoiAreaRequestValidator;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PoiSearchService {

    private static final int DEFAULT_LIMIT = 200;

    private final PointOfInterestRepository poiRepository;
    private final PoiAreaRequestValidator validator;

    public PoiSearchInAreaResponseDTO searchInArea(PoiSearchInAreaRequestDTO req) {
        validator.validate(req);

        int page = req.getPage() == null ? 0 : req.getPage();
        int limit = req.getLimit() == null ? DEFAULT_LIMIT : req.getLimit();

        List<String> categories = (req.getCategories() == null) ? List.of() : req.getCategories();

        List<PointOfInterest> candidates;

        if (req.getSelectionType() == PoiSearchInAreaRequestDTO.SelectionType.BBOX) {
            candidates = fetchByBbox(req.getBbox(), categories);
        } else {
            // POLYGON: bbox ile adayları çek → Java point-in-polygon filtrele
            var poly = req.getPolygon();
            var bbox = computeBbox(poly);

            candidates = fetchByBbox(
                    new PoiSearchInAreaRequestDTO.Bbox(bbox.minLat, bbox.minLng, bbox.maxLat, bbox.maxLng),
                    categories
            );

            candidates = candidates.stream()
                    .filter(p -> pointInPolygon(p.getLatitude(), p.getLongitude(), poly))
                    .collect(Collectors.toList());
        }

        // sorting (opsiyonel)
        candidates = applySorting(candidates, req);

        // countsByCategory (opsiyonel UI panel)
        Map<String, Integer> countsByCategory = candidates.stream()
                .collect(Collectors.toMap(
                        PointOfInterest::getCategory,
                        x -> 1,
                        Integer::sum,
                        LinkedHashMap::new
                ));

        // pagination
        int fromIndex = Math.min(page * limit, candidates.size());
        int toIndex = Math.min(fromIndex + limit, candidates.size());
        List<PointOfInterest> paged = candidates.subList(fromIndex, toIndex);

        List<PoiSearchInAreaResponseDTO.PoiSummaryDTO> pois = paged.stream()
                .map(this::toSummary)
                .toList();

        return PoiSearchInAreaResponseDTO.builder()
                .count(candidates.size())
                .pois(pois)
                .countsByCategory(countsByCategory)
                .build();
    }

    private List<PointOfInterest> fetchByBbox(PoiSearchInAreaRequestDTO.Bbox b, List<String> categories) {
        if (categories == null || categories.isEmpty()) {
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

    private List<PointOfInterest> applySorting(List<PointOfInterest> list, PoiSearchInAreaRequestDTO req) {
        if (req.getSort() == null) return list;

        if (req.getSort() == PoiSearchInAreaRequestDTO.SortType.RATING_DESC) {
            return list.stream()
                    .sorted(Comparator.comparing(PointOfInterest::getRating, Comparator.nullsLast(Double::compareTo)).reversed())
                    .toList();
        }

        if (req.getSort() == PoiSearchInAreaRequestDTO.SortType.DISTANCE_TO_CENTER) {
            Center c = computeCenter(req);
            return list.stream()
                    .sorted(Comparator.comparingDouble(p -> distanceApprox(p.getLatitude(), p.getLongitude(), c.lat, c.lng)))
                    .toList();
        }

        return list;
    }

    private Center computeCenter(PoiSearchInAreaRequestDTO req) {
        if (req.getSelectionType() == PoiSearchInAreaRequestDTO.SelectionType.BBOX) {
            var b = req.getBbox();
            return new Center((b.getMinLat() + b.getMaxLat()) / 2.0, (b.getMinLng() + b.getMaxLng()) / 2.0);
        }
        var poly = req.getPolygon();
        double lat = poly.stream().mapToDouble(PoiSearchInAreaRequestDTO.LatLng::getLat).average().orElse(0);
        double lng = poly.stream().mapToDouble(PoiSearchInAreaRequestDTO.LatLng::getLng).average().orElse(0);
        return new Center(lat, lng);
    }

    private static double distanceApprox(double lat1, double lng1, double lat2, double lng2) {
        double dLat = lat1 - lat2;
        double dLng = lng1 - lng2;
        return dLat * dLat + dLng * dLng;
    }

    private static class Center {
        double lat;
        double lng;
        Center(double lat, double lng) { this.lat = lat; this.lng = lng; }
    }

    private static class BboxCalc {
        double minLat, minLng, maxLat, maxLng;
        BboxCalc(double minLat, double minLng, double maxLat, double maxLng) {
            this.minLat = minLat; this.minLng = minLng; this.maxLat = maxLat; this.maxLng = maxLng;
        }
    }

    private static BboxCalc computeBbox(List<PoiSearchInAreaRequestDTO.LatLng> poly) {
        double minLat = Double.POSITIVE_INFINITY, minLng = Double.POSITIVE_INFINITY;
        double maxLat = Double.NEGATIVE_INFINITY, maxLng = Double.NEGATIVE_INFINITY;
        for (var p : poly) {
            minLat = Math.min(minLat, p.getLat());
            minLng = Math.min(minLng, p.getLng());
            maxLat = Math.max(maxLat, p.getLat());
            maxLng = Math.max(maxLng, p.getLng());
        }
        return new BboxCalc(minLat, minLng, maxLat, maxLng);
    }

    // Ray-casting algorithm
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