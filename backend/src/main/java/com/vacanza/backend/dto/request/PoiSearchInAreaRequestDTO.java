package com.vacanza.backend.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PoiSearchInAreaRequestDTO {

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

    public enum SelectionType {POLYGON, BBOX}

    public enum SortType {RATING_DESC, DISTANCE_TO_CENTER}

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