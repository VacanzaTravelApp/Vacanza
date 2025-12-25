package com.vacanza.backend.dto.request;

import lombok.*;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PoiSearchInAreaRequestDTO {

    private SelectionType selectionType; // POLYGON ya da BBOX

    private Bbox bbox;                   // selectionType=BBOX için zorunlu
    private List<LatLng> polygon;        // selectionType=POLYGON için zorunlu

    private List<String> categories;     // optional (boş/null => tüm kategoriler)
    private Integer page;                // optional (default 0)
    private Integer limit;               // optional (default 200)
    private SortType sort;               // optional

    public enum SelectionType { POLYGON, BBOX }
    public enum SortType { DISTANCE_TO_CENTER, RATING_DESC }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Bbox {
        private Double minLat;
        private Double minLng;
        private Double maxLat;
        private Double maxLng;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class LatLng {
        private Double lat;
        private Double lng;
    }
}