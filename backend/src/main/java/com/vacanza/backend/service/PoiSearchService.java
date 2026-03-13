package com.vacanza.backend.service;

import com.vacanza.backend.dto.request.PoiSearchInAreaRequestDTO;
import com.vacanza.backend.dto.response.PoiSearchInAreaResponseDTO;
import com.vacanza.backend.entity.IngestedTile;
import com.vacanza.backend.entity.PointOfInterest;
import com.vacanza.backend.repo.IngestedTileRepository;
import com.vacanza.backend.repo.PointOfInterestRepository;
import com.vacanza.backend.util.TileUtils;
import com.vacanza.backend.validation.PoiAreaRequestValidator;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PoiSearchService {

    private final PointOfInterestRepository poiRepository;
    private final PoiIngestService poiIngestService;
    private final IngestedTileRepository ingestedTileRepository;
    private final PoiAreaRequestValidator validator;

    private static final int DEFAULT_PAGE = 0;
    private static final int DEFAULT_LIMIT = 500;
    private static final int INGEST_LIMIT = 50;
    private static final int MAX_TILES_TO_INGEST = 25;
    private static final int MIN_TILE_ZOOM = 10;
    private static final int MAX_TILE_ZOOM = 14;

    public PoiSearchInAreaResponseDTO searchInArea(PoiSearchInAreaRequestDTO request) {

        validator.validate(request);

        int page = request.getPage() != null ? request.getPage() : DEFAULT_PAGE;
        int limit = request.getLimit() != null ? request.getLimit() : DEFAULT_LIMIT;

        PoiSearchInAreaRequestDTO.Bbox bbox = resolveBbox(request);

        List<String> frontendCategories = request.getCategories() == null
                ? List.of()
                : request.getCategories().stream()
                        .map(String::toLowerCase)
                        .distinct()
                        .toList();

        final PoiSearchInAreaRequestDTO.Bbox bboxFinal = bbox;
        final List<String> categoriesFinal = frontendCategories;
        CompletableFuture.runAsync(() -> {
            try {
                ingestMissingTiles(bboxFinal, categoriesFinal);
            } catch (Exception ignored) {
            }
        });

        List<PointOfInterest> all = fetchByBbox(bbox, frontendCategories);

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

    private void ingestMissingTiles(
            PoiSearchInAreaRequestDTO.Bbox bbox,
            List<String> frontendCategories) {

        if (frontendCategories.isEmpty()) return;

        int chosenZoom = chooseTileZoom(bbox);
        if (chosenZoom < MIN_TILE_ZOOM) return;

        List<TileUtils.TileCoord> tiles = TileUtils.tilesForBbox(
                bbox.getMinLat(), bbox.getMinLng(),
                bbox.getMaxLat(), bbox.getMaxLng(),
                chosenZoom);

        for (String category : frontendCategories) {
            if (poiIngestService.mapFrontendToGeoapify(category) == null) continue;

            Set<String> ingestedKeys = findIngestedKeys(tiles, chosenZoom, category);

            for (TileUtils.TileCoord tile : tiles) {
                String key = tile.x() + ":" + tile.y();
                if (ingestedKeys.contains(key)) continue;

                poiIngestService.ingestTile(tile, category, INGEST_LIMIT);
            }
        }
    }

    private int chooseTileZoom(PoiSearchInAreaRequestDTO.Bbox bbox) {
        for (int z = MAX_TILE_ZOOM; z >= MIN_TILE_ZOOM; z--) {
            List<TileUtils.TileCoord> tiles = TileUtils.tilesForBbox(
                    bbox.getMinLat(), bbox.getMinLng(),
                    bbox.getMaxLat(), bbox.getMaxLng(), z);
            if (tiles.size() <= MAX_TILES_TO_INGEST) return z;
        }
        return MIN_TILE_ZOOM - 1;
    }

    private Set<String> findIngestedKeys(
            List<TileUtils.TileCoord> tiles, int zoom, String category) {
        if (tiles.isEmpty()) return Set.of();

        int minX = Integer.MAX_VALUE, maxX = Integer.MIN_VALUE;
        int minY = Integer.MAX_VALUE, maxY = Integer.MIN_VALUE;

        for (TileUtils.TileCoord t : tiles) {
            minX = Math.min(minX, t.x());
            maxX = Math.max(maxX, t.x());
            minY = Math.min(minY, t.y());
            maxY = Math.max(maxY, t.y());
        }

        List<IngestedTile> existing = ingestedTileRepository
                .findByZoomLevelAndTileXBetweenAndTileYBetweenAndCategory(
                        zoom, minX, maxX, minY, maxY, category);

        return existing.stream()
                .map(it -> it.getTileX() + ":" + it.getTileY())
                .collect(Collectors.toSet());
    }

}
