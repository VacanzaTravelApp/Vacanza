package com.vacanza.backend.service;

import com.vacanza.backend.dto.internal.PoiResult;
import com.vacanza.backend.dto.request.PoiSearchInAreaRequestDTO;
import com.vacanza.backend.dto.response.PoiSearchInAreaResponseDTO;
import com.vacanza.backend.dto.response.PoiSearchMapboxStreamChunkDTO;
import com.vacanza.backend.dto.response.PoiSearchMapboxStreamDoneDTO;
import com.vacanza.backend.entity.PointOfInterest;
import com.vacanza.backend.integration.MapboxPoiSearchClient;
import com.vacanza.backend.repo.PointOfInterestRepository;
import com.vacanza.backend.util.PolygonRouteGeometry;
import com.vacanza.backend.validation.PoiAreaRequestValidator;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.function.Consumer;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class PoiSearchService {

    private final PointOfInterestRepository poiRepository;
    private final PoiIngestService poiIngestService;
    private final PoiAreaRequestValidator validator;
    private final MapboxPoiSearchClient mapboxPoiSearchClient;

    private static final int DEFAULT_PAGE = 0;
    private static final int DEFAULT_LIMIT = 200;
    private static final int INGEST_LIMIT = 20;

    /** Web map UI keys → Mapbox Search Box category slugs (deduped across keys). */
    private static final Map<String, List<String>> WEB_UI_TO_MAPBOX_SLUGS = Map.ofEntries(
            Map.entry("restaurant", List.of("restaurant")),
            Map.entry("cafe", List.of("cafe")),
            Map.entry("museum", List.of("museum", "art_gallery", "aquarium", "zoo")),
            Map.entry("monuments", List.of("monument", "historic_site", "place_of_worship")),
            Map.entry("park", List.of("park")),
            Map.entry("attraction", List.of("tourist_attraction")),
            Map.entry("bar", List.of("bar")),
            Map.entry("shopping", List.of("shopping_mall", "market")),
            Map.entry("hotel", List.of("hotel")),
            Map.entry("transport", List.of("bus_stop", "train_station")),
            Map.entry("others", List.of("landmark")));

    private static final List<String> DEFAULT_MAPBOX_SLUGS_WHEN_NO_FILTER = List.of(
            "restaurant", "cafe", "museum", "monument", "park",
            "tourist_attraction", "bar", "shopping_mall", "hotel", "landmark");

    private static final int MAPBOX_TILED_BUDGET = 96;

    /**
     * Progressive Mapbox fetch: one chunk per UI filter bucket in this order so the client can render early.
     */
    private static final List<String> STREAM_UI_PRIORITY = List.of(
            "restaurant", "cafe", "bar", "museum", "monuments", "park",
            "attraction", "shopping", "hotel", "transport", "others");

    public PoiSearchInAreaResponseDTO searchInArea(PoiSearchInAreaRequestDTO request) {

        validator.validate(request);

        if (Boolean.TRUE.equals(request.getMapboxAreaSearch())) {
            return searchInAreaFromMapbox(request);
        }

        int page = request.getPage() != null ? request.getPage() : DEFAULT_PAGE;
        int limit = request.getLimit() != null ? request.getLimit() : DEFAULT_LIMIT;

        PoiSearchInAreaRequestDTO.Bbox bbox = resolveBbox(request);

        List<String> frontendCategories = request.getCategories() == null
                ? List.of()
                : request.getCategories().stream()
                        .map(String::toLowerCase)
                        .distinct()
                        .toList();

        List<PointOfInterest> all = fetchByBbox(bbox, frontendCategories);

        // No results in DB — trigger ingest from Mapbox + Foursquare
        if (all.isEmpty()) {

            poiIngestService.ingestMultipleCategories(
                    bbox.getMinLng(), bbox.getMinLat(),
                    bbox.getMaxLng(), bbox.getMaxLat(),
                    frontendCategories,
                    INGEST_LIMIT);

            all = fetchByBbox(bbox, frontendCategories);
        }

        // sort
        if (request.getSort() == PoiSearchInAreaRequestDTO.SortType.DISTANCE_TO_CENTER) {
            sortByDistanceToCenter(all, bbox);
        } else {
            all.sort(
                    Comparator.comparing(
                            PointOfInterest::getRating,
                            Comparator.nullsLast(Double::compareTo)).reversed());
        }

        Map<String, Integer> countsByCategory = all.stream()
                .collect(Collectors.groupingBy(
                        PointOfInterest::getCategory,
                        Collectors.summingInt(x -> 1)));

        int from = Math.min(page * limit, all.size());
        int to = Math.min(from + limit, all.size());

        List<PoiSearchInAreaResponseDTO.PoiSummaryDTO> pois = all.subList(from, to).stream()
                .map(this::toSummary)
                .toList();

        return PoiSearchInAreaResponseDTO.builder()
                .count(all.size())
                .pois(pois)
                .countsByCategory(countsByCategory)
                .build();
    }

    private PoiSearchInAreaResponseDTO searchInAreaFromMapbox(PoiSearchInAreaRequestDTO request) {
        int page = request.getPage() != null ? request.getPage() : DEFAULT_PAGE;
        int limit = request.getLimit() != null ? request.getLimit() : DEFAULT_LIMIT;

        PoiSearchInAreaRequestDTO.Bbox bbox = resolveBbox(request);
        double minLon = bbox.getMinLng();
        double minLat = bbox.getMinLat();
        double maxLon = bbox.getMaxLng();
        double maxLat = bbox.getMaxLat();

        double km2 = PolygonRouteGeometry.bboxAreaKm2(minLon, minLat, maxLon, maxLat);
        int grid = gridForAreaKm2(km2);
        LinkedHashSet<String> slugs = resolveMapboxSlugs(request.getCategories());
        while (grid > 1 && slugs.size() * grid * grid > MAPBOX_TILED_BUDGET) {
            grid--;
        }

        Map<String, PoiResult> merged = new LinkedHashMap<>();
        for (String slug : slugs) {
            for (PoiResult p : mapboxPoiSearchClient.searchByCategoryTiled(
                    slug, minLon, minLat, maxLon, maxLat, grid)) {
                if (p == null || p.getName() == null || p.getName().isBlank()) {
                    continue;
                }
                merged.putIfAbsent(mapboxDedupKey(p), p);
            }
        }

        List<PoiResult> list = new ArrayList<>(merged.values());

        if (request.getSelectionType() == PoiSearchInAreaRequestDTO.SelectionType.POLYGON) {
            List<double[]> ring = polygonToRing(request.getPolygon());
            list = new ArrayList<>(list.stream()
                    .filter(p -> PolygonRouteGeometry.pointInPolygon(p.getLon(), p.getLat(), ring))
                    .toList());
        }

        if (request.getSort() == PoiSearchInAreaRequestDTO.SortType.DISTANCE_TO_CENTER) {
            sortPoiResultsByDistanceToCenter(list, bbox);
        } else {
            list.sort(Comparator
                    .comparing(PoiResult::getRating, Comparator.nullsFirst(Double::compareTo))
                    .reversed()
                    .thenComparing(
                            p -> p.getName() != null ? p.getName() : "",
                            String.CASE_INSENSITIVE_ORDER));
        }

        Map<String, Integer> countsByCategory = list.stream()
                .collect(Collectors.groupingBy(
                        p -> p.getCategory() != null ? p.getCategory() : "unknown",
                        Collectors.summingInt(x -> 1)));

        int from = Math.min(page * limit, list.size());
        int to = Math.min(from + limit, list.size());
        List<PoiSearchInAreaResponseDTO.PoiSummaryDTO> pois = list.subList(from, to).stream()
                .map(this::toSummaryFromMapbox)
                .toList();

        persistMapboxAreaResults(list);

        return PoiSearchInAreaResponseDTO.builder()
                .count(list.size())
                .pois(pois)
                .countsByCategory(countsByCategory)
                .build();
    }

    /**
     * Emits {@link PoiSearchMapboxStreamChunkDTO} per UI category wave, then {@link PoiSearchMapboxStreamDoneDTO}.
     * Respects {@code request.limit} as max distinct POIs (same cap as non-streaming mapbox path).
     */
    public void forEachMapboxStreamChunk(
            PoiSearchInAreaRequestDTO request,
            Consumer<Object> emit) {

        int maxDistinct = request.getLimit() != null ? request.getLimit() : DEFAULT_LIMIT;

        PoiSearchInAreaRequestDTO.Bbox bbox = resolveBbox(request);
        double minLon = bbox.getMinLng();
        double minLat = bbox.getMinLat();
        double maxLon = bbox.getMaxLng();
        double maxLat = bbox.getMaxLat();

        List<double[]> ring = request.getSelectionType() == PoiSearchInAreaRequestDTO.SelectionType.POLYGON
                ? polygonToRing(request.getPolygon())
                : null;

        double km2 = PolygonRouteGeometry.bboxAreaKm2(minLon, minLat, maxLon, maxLat);
        int baseGrid = gridForAreaKm2(km2);

        List<String> uiKeys = orderedUiKeysForStream(request.getCategories());
        Set<String> seen = new HashSet<>();
        Map<String, PoiResult> toPersist = new LinkedHashMap<>();
        Map<String, Integer> runningCounts = new HashMap<>();
        int chunkIndex = 0;

        for (String uiKey : uiKeys) {
            if (seen.size() >= maxDistinct) {
                break;
            }

            String uiNorm = uiKey.toLowerCase(Locale.ROOT).trim();
            LinkedHashSet<String> slugs = new LinkedHashSet<>(
                    WEB_UI_TO_MAPBOX_SLUGS.getOrDefault(uiNorm, List.of(uiNorm)));

            int grid = baseGrid;
            while (grid > 1 && slugs.size() * grid * grid > MAPBOX_TILED_BUDGET) {
                grid--;
            }

            Map<String, PoiResult> chunkMerged = new LinkedHashMap<>();
            for (String slug : slugs) {
                if (seen.size() >= maxDistinct) {
                    break;
                }
                for (PoiResult p : mapboxPoiSearchClient.searchByCategoryTiled(
                        slug, minLon, minLat, maxLon, maxLat, grid)) {
                    if (p == null || p.getName() == null || p.getName().isBlank()) {
                        continue;
                    }
                    if (ring != null && !PolygonRouteGeometry.pointInPolygon(p.getLon(), p.getLat(), ring)) {
                        continue;
                    }
                    chunkMerged.putIfAbsent(mapboxDedupKey(p), p);
                }
            }

            List<PoiResult> newForChunk = new ArrayList<>();
            for (PoiResult p : chunkMerged.values()) {
                if (seen.size() >= maxDistinct) {
                    break;
                }
                String dedup = mapboxDedupKey(p);
                if (!seen.add(dedup)) {
                    continue;
                }
                newForChunk.add(p);
                toPersist.put(dedup, copyPoiForPersist(p, uiNorm));
                String cat = p.getCategory() != null ? p.getCategory() : "unknown";
                runningCounts.merge(cat, 1, Integer::sum);
            }

            if (request.getSort() == PoiSearchInAreaRequestDTO.SortType.DISTANCE_TO_CENTER) {
                sortPoiResultsByDistanceToCenter(newForChunk, bbox);
            } else {
                newForChunk.sort(Comparator
                        .comparing(PoiResult::getRating, Comparator.nullsFirst(Double::compareTo))
                        .reversed()
                        .thenComparing(
                                p -> p.getName() != null ? p.getName() : "",
                                String.CASE_INSENSITIVE_ORDER));
            }

            List<PoiSearchInAreaResponseDTO.PoiSummaryDTO> summaries = newForChunk.stream()
                    .map(this::toSummaryFromMapbox)
                    .toList();

            emit.accept(PoiSearchMapboxStreamChunkDTO.builder()
                    .type("chunk")
                    .uiCategory(uiKey)
                    .chunkIndex(chunkIndex++)
                    .pois(summaries)
                    .countsSoFar(Map.copyOf(runningCounts))
                    .build());
        }

        emit.accept(PoiSearchMapboxStreamDoneDTO.builder()
                .type("done")
                .totalDistinct(seen.size())
                .countsByCategory(Map.copyOf(runningCounts))
                .build());

        persistMapboxAreaResults(toPersist.values());
    }

    private void persistMapboxAreaResults(Collection<PoiResult> results) {
        if (results == null || results.isEmpty()) {
            return;
        }
        try {
            poiIngestService.ingestFromMapboxResults(results);
        } catch (Exception e) {
            log.warn("[POI] mapbox area persist failed: {}", e.getMessage());
        }
    }

    /** DB row uses web UI category key (e.g. restaurant, monuments). */
    private static PoiResult copyPoiForPersist(PoiResult p, String categoryUiKey) {
        String key = categoryUiKey != null ? categoryUiKey.toLowerCase(Locale.ROOT).trim() : "others";
        PoiResult o = new PoiResult(
                p.getName(),
                key,
                p.getLat(),
                p.getLon());
        o.setMapboxId(p.getMapboxId());
        o.setExternalId(p.getExternalId());
        if (p.getExternalIds() != null) {
            o.setExternalIds(Map.copyOf(p.getExternalIds()));
        }
        if (p.getPoiCategoryIds() != null) {
            o.setPoiCategoryIds(List.copyOf(p.getPoiCategoryIds()));
        }
        o.setMaki(p.getMaki());
        o.setRating(p.getRating());
        return o;
    }

    private static List<String> orderedUiKeysForStream(List<String> requestCategories) {
        if (requestCategories == null || requestCategories.isEmpty()) {
            return List.copyOf(STREAM_UI_PRIORITY);
        }
        Set<String> wanted = new LinkedHashSet<>();
        for (String raw : requestCategories) {
            if (raw != null && !raw.isBlank()) {
                wanted.add(raw.toLowerCase(Locale.ROOT).trim());
            }
        }
        List<String> out = new ArrayList<>();
        for (String key : STREAM_UI_PRIORITY) {
            if (wanted.contains(key)) {
                out.add(key);
            }
        }
        for (String w : wanted) {
            if (!out.contains(w)) {
                out.add(w);
            }
        }
        return out;
    }

    private static LinkedHashSet<String> resolveMapboxSlugs(List<String> frontendCategories) {
        LinkedHashSet<String> out = new LinkedHashSet<>();
        if (frontendCategories == null || frontendCategories.isEmpty()) {
            out.addAll(DEFAULT_MAPBOX_SLUGS_WHEN_NO_FILTER);
            return out;
        }
        for (String raw : frontendCategories) {
            if (raw == null || raw.isBlank()) {
                continue;
            }
            String key = raw.toLowerCase(Locale.ROOT).trim();
            List<String> mapped = WEB_UI_TO_MAPBOX_SLUGS.get(key);
            if (mapped != null) {
                out.addAll(mapped);
            } else {
                out.add(key);
            }
        }
        return out;
    }

    private static int gridForAreaKm2(double km2) {
        if (!Double.isFinite(km2) || km2 <= 0) {
            return 3;
        }
        if (km2 < 2) {
            return 2;
        }
        if (km2 < 30) {
            return 3;
        }
        if (km2 < 120) {
            return 4;
        }
        return 5;
    }

    private static String mapboxDedupKey(PoiResult p) {
        if (p.getMapboxId() != null && !p.getMapboxId().isBlank()) {
            return p.getMapboxId();
        }
        if (p.getExternalId() != null && !p.getExternalId().isBlank()) {
            return "fsq:" + p.getExternalId();
        }
        String name = p.getName() != null ? p.getName().toLowerCase(Locale.ROOT) : "";
        return String.format(Locale.ROOT, "%s|%.5f|%.5f", name, p.getLat(), p.getLon());
    }

    private static List<double[]> polygonToRing(List<PoiSearchInAreaRequestDTO.LatLng> polygon) {
        List<double[]> ring = new ArrayList<>();
        for (PoiSearchInAreaRequestDTO.LatLng p : polygon) {
            ring.add(new double[] { p.getLng(), p.getLat() });
        }
        return ring;
    }

    private static void sortPoiResultsByDistanceToCenter(List<PoiResult> pois, PoiSearchInAreaRequestDTO.Bbox b) {
        double cl = (b.getMinLat() + b.getMaxLat()) / 2;
        double cg = (b.getMinLng() + b.getMaxLng()) / 2;
        pois.sort(Comparator.comparingDouble(
                p -> Math.pow(cl - p.getLat(), 2) + Math.pow(cg - p.getLon(), 2)));
    }

    private PoiSearchInAreaResponseDTO.PoiSummaryDTO toSummaryFromMapbox(PoiResult p) {
        String basis = p.getMapboxId();
        if (basis == null || basis.isBlank()) {
            basis = (p.getExternalId() != null ? p.getExternalId() : "")
                    + "|" + p.getName() + "|" + p.getLat() + "|" + p.getLon();
        }
        UUID id = UUID.nameUUIDFromBytes(basis.getBytes(StandardCharsets.UTF_8));
        return PoiSearchInAreaResponseDTO.PoiSummaryDTO.builder()
                .poiId(id)
                .name(p.getName())
                .category(p.getCategory())
                .latitude(p.getLat())
                .longitude(p.getLon())
                .rating(p.getRating())
                .priceLevel(p.getPriceLevel())
                .externalId(p.getExternalId())
                .build();
    }

    // ================= HELPERS =================

    private List<PointOfInterest> fetchByBbox(
            PoiSearchInAreaRequestDTO.Bbox b,
            List<String> categories) {
        if (categories.isEmpty()) {
            return poiRepository.findByLatitudeBetweenAndLongitudeBetween(
                    b.getMinLat(), b.getMaxLat(),
                    b.getMinLng(), b.getMaxLng());
        }

        return poiRepository.findByLatitudeBetweenAndLongitudeBetweenAndCategoryIn(
                b.getMinLat(), b.getMaxLat(),
                b.getMinLng(), b.getMaxLng(),
                categories);
    }

    private PoiSearchInAreaRequestDTO.Bbox resolveBbox(PoiSearchInAreaRequestDTO r) {
        if (r.getSelectionType() == PoiSearchInAreaRequestDTO.SelectionType.BBOX) {
            return r.getBbox();
        }
        return bboxFromPolygon(r.getPolygon());
    }

    private PoiSearchInAreaRequestDTO.Bbox bboxFromPolygon(
            List<PoiSearchInAreaRequestDTO.LatLng> poly) {
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
            PoiSearchInAreaRequestDTO.Bbox b) {
        double cl = (b.getMinLat() + b.getMaxLat()) / 2;
        double cg = (b.getMinLng() + b.getMaxLng()) / 2;

        pois.sort(Comparator.comparingDouble(
                p -> Math.pow(cl - p.getLatitude(), 2)
                        + Math.pow(cg - p.getLongitude(), 2)));
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

}
