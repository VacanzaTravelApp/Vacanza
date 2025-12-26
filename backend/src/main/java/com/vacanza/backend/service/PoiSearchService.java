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

import java.util.*;
import java.util.stream.Collectors;

@Service
@AllArgsConstructor
public class PoiSearchService implements PoiSearchImpl {

    // =====================================================
    // ===================== CONSTANTS =====================
    // =====================================================

    private static final int DEFAULT_PAGE = 0;
    private static final int DEFAULT_LIMIT = 200;

    /** Hard guard: UI veya abuse sonucu çok fazla POI dönmesin */
    private static final int MAX_RESULT_COUNT = 5000;

    /** DB query için maksimum bbox alanı */
    private static final double MAX_BBOX_AREA = 25.0;

    /** Ingest için daha geniş ama yine de sınırlı alan */
    private static final double MAX_INGEST_BBOX_AREA = 400.0;

    /** Geoapify polygon karmaşıklık limiti */
    private static final int MAX_GEOAPIFY_POLYGON_POINTS = 10;

    // =====================================================
    // ================= DEPENDENCIES ======================
    // =====================================================

    private final PointOfInterestRepository poiRepository;
    private final PoiAreaRequestValidator validator;
    private final PoiIngestService poiIngestService;

    // =====================================================
    // ============ FRONTEND → GEOAPIFY MAP =================
    // =====================================================

    /**
     * Frontend category → Geoapify taxonomy map
     * Frontend ASLA Geoapify category bilmez.
     */
    private static final Map<String, List<String>> GEOAPIFY_CATEGORY_MAP = Map.of(
            "museum", List.of("tourism.museum"),
            "restaurant", List.of("catering.restaurant"),
            "cafe", List.of("catering.cafe"),
            "bar", List.of("catering.bar"),
            "hotel", List.of("accommodation.hotel"),
            "park", List.of("leisure.park"),
            "cinema", List.of("entertainment.cinema")
    );

    // =====================================================
    // ===================== MAIN FLOW =====================
    // =====================================================

    @Override
    public PoiSearchInAreaResponseDTO searchInArea(PoiSearchInAreaRequestDTO request) {

        // 1) Structural + logical validation
        validator.validate(request);

        // 2) Pagination defaults
        int page = request.getPage() != null ? request.getPage() : DEFAULT_PAGE;
        int limit = request.getLimit() != null ? request.getLimit() : DEFAULT_LIMIT;

        // 3) Resolve bbox (polygon → bbox if needed)
        PoiSearchInAreaRequestDTO.Bbox bbox = resolveBbox(request);

        // 4) DB safety guard
        guardBboxSize(bbox);

        // 5) Normalize FRONTEND categories (DB filter için)
        List<String> dbCategories =
                request.getCategories() == null
                        ? List.of()
                        : request.getCategories().stream()
                        .map(PoiSearchService::normalizeCategory)
                        .filter(s -> s != null && !s.isBlank())
                        .distinct()
                        .toList();

        // 6) Fetch from DB first
        List<PointOfInterest> all = fetchByBbox(bbox, dbCategories);
        System.out.println("FETCH RESULT SIZE = " + all.size());

        // =================================================
        // 7) DB EMPTY → INGEST FROM GEOAPIFY
        // =================================================
        if (all.isEmpty()) {

            guardIngestBboxSize(bbox);

            // Geoapify filter (polygon or bbox, safe)
            String geoapifyFilter = buildGeoapifyFilter(request);
            System.out.println("DB EMPTY -> INGEST (GEOAPIFY) filter=" + geoapifyFilter);

            // 🔥 EN KRİTİK NOKTA:
            // Frontend categories → Geoapify categories
            List<String> geoapifyCategories =
                    mapToGeoapifyCategories(request.getCategories());

            int saved = poiIngestService.ingestFromGeoapifyArea(
                    geoapifyFilter,
                    geoapifyCategories,
                    20
            );

            System.out.println("INGEST saved=" + saved);

            // Re-fetch after ingest
            all = fetchByBbox(bbox, dbCategories);
        }

        // 8) Hard guard
        if (all.size() > MAX_RESULT_COUNT) {
            throw new ResponseStatusException(
                    HttpStatus.UNPROCESSABLE_ENTITY,
                    "TOO_MANY_RESULTS"
            );
        }

        // 9) Sorting
        PoiSearchInAreaRequestDTO.SortType sort =
                request.getSort() != null
                        ? request.getSort()
                        : PoiSearchInAreaRequestDTO.SortType.RATING_DESC;

        if (sort == PoiSearchInAreaRequestDTO.SortType.DISTANCE_TO_CENTER) {
            sortByDistanceToBboxCenter(all, bbox);
        } else {
            all.sort(
                    Comparator.comparing(
                            PointOfInterest::getRating,
                            Comparator.nullsLast(Double::compareTo)
                    ).reversed()
            );
        }

        // 10) countsByCategory (UI filter panel için)
        Map<String, Integer> countsByCategory = all.stream()
                .collect(Collectors.groupingBy(
                        p -> normalizeCategory(p.getCategory()),
                        Collectors.summingInt(x -> 1)
                ));

        // 11) Pagination
        int from = Math.min(page * limit, all.size());
        int to = Math.min(from + limit, all.size());
        List<PointOfInterest> pageItems = all.subList(from, to);

        // 12) Entity → DTO
        List<PoiSearchInAreaResponseDTO.PoiSummaryDTO> pois =
                pageItems.stream()
                        .map(this::toSummary)
                        .toList();

        // 13) Response
        return PoiSearchInAreaResponseDTO.builder()
                .count(all.size())
                .pois(pois)
                .countsByCategory(countsByCategory)
                .build();
    }

    // =====================================================
    // ===================== HELPERS =======================
    // =====================================================

    private PoiSearchInAreaRequestDTO.Bbox resolveBbox(PoiSearchInAreaRequestDTO request) {
        if (request.getSelectionType() == PoiSearchInAreaRequestDTO.SelectionType.BBOX) {
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

        return new PoiSearchInAreaRequestDTO.Bbox(minLat, minLng, maxLat, maxLng);
    }

    private void guardBboxSize(PoiSearchInAreaRequestDTO.Bbox bbox) {
        double area =
                (bbox.getMaxLat() - bbox.getMinLat())
                        * (bbox.getMaxLng() - bbox.getMinLng());
        if (area > MAX_BBOX_AREA) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "BBOX_TOO_LARGE");
        }
    }

    private void guardIngestBboxSize(PoiSearchInAreaRequestDTO.Bbox bbox) {
        double area =
                (bbox.getMaxLat() - bbox.getMinLat())
                        * (bbox.getMaxLng() - bbox.getMinLng());
        if (area > MAX_INGEST_BBOX_AREA) {
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "INGEST_BBOX_TOO_LARGE");
        }
    }

    private List<PointOfInterest> fetchByBbox(
            PoiSearchInAreaRequestDTO.Bbox bbox,
            List<String> categories
    ) {
        if (categories.isEmpty()) {
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

    private static String normalizeCategory(String s) {
        return s == null ? null : s.trim().toLowerCase();
    }

    /**
     * Builds Geoapify filter safely.
     * - POLYGON çok karmaşıksa → bbox fallback
     * - Locale.US → decimal separator fix
     */
    private String buildGeoapifyFilter(PoiSearchInAreaRequestDTO req) {

        if (req.getSelectionType() == PoiSearchInAreaRequestDTO.SelectionType.BBOX) {
            var b = req.getBbox();
            return String.format(
                    Locale.US,
                    "rect:%f,%f,%f,%f",
                    b.getMinLng(),
                    b.getMinLat(),
                    b.getMaxLng(),
                    b.getMaxLat()
            );
        }

        var polygon = req.getPolygon();
        if (polygon == null || polygon.size() < 3) {
            throw new IllegalArgumentException("Polygon must have at least 3 points");
        }

        // Geoapify polygon complexity guard
        if (polygon.size() > MAX_GEOAPIFY_POLYGON_POINTS) {
            var bbox = bboxFromPolygon(polygon);
            return String.format(
                    Locale.US,
                    "rect:%f,%f,%f,%f",
                    bbox.getMinLng(),
                    bbox.getMinLat(),
                    bbox.getMaxLng(),
                    bbox.getMaxLat()
            );
        }

        StringBuilder sb = new StringBuilder("polygon:");
        for (int i = 0; i < polygon.size(); i++) {
            var p = polygon.get(i);
            sb.append(p.getLng()).append(" ").append(p.getLat());
            if (i < polygon.size() - 1) sb.append(",");
        }

        return sb.toString();
    }

    /**
     * Frontend categories → Geoapify taxonomy
     * Eğer frontend boş gönderirse default sights kullanılır.
     */
    private List<String> mapToGeoapifyCategories(List<String> frontendCategories) {

        if (frontendCategories == null || frontendCategories.isEmpty()) {
            return List.of("tourism.sights");
        }

        List<String> result = new ArrayList<>();

        for (String c : frontendCategories) {
            switch (c.toLowerCase()) {
                case "museum" -> result.add("entertainment.museum"); // 🔥 FIX
                case "restaurant" -> result.add("catering.restaurant");
                case "cafe" -> result.add("catering.cafe");
                case "supermarket", "market" -> result.add("commercial.supermarket");
            }
        }

        if (result.isEmpty()) {
            result.add("tourism.sights");
        }

        return result;
    }







}
