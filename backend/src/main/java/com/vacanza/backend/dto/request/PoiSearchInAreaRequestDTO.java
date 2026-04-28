package com.vacanza.backend.dto.request;

import lombok.*;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PoiSearchInAreaRequestDTO {

    public enum SelectionType { POLYGON, BBOX }
    public enum SortType { RATING_DESC, DISTANCE_TO_CENTER }

    private SelectionType selectionType;

    // selectionType=BBOX ise dolu olmalı
    private Bbox bbox;

    // selectionType=POLYGON ise dolu olmalı (min 3 point)
    private List<LatLng> polygon;

    // optional: kategori filtresi (null/empty => filtre yok)
    private List<String> categories;

    // optional pagination
    private Integer page;   // default 0
    private Integer limit;  // default 200, max 500

    // optional sort
    private SortType sort;

    /**
     * When true, POIs are loaded from Mapbox Search Box (tiled category search within the area)
     * instead of the local DB. Intended for web drawn polygons where exhaustive coverage matters.
     */
    private Boolean mapboxAreaSearch;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LatLng {
        private Double lat;
        private Double lng;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Bbox {
        private Double minLat;
        private Double minLng;
        private Double maxLat;
        private Double maxLng;
    }
}