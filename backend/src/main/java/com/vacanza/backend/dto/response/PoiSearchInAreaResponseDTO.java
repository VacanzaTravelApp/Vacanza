package com.vacanza.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PoiSearchInAreaResponseDTO {

    private int count; // filtre sonrası toplam
    private List<PoiSummaryDTO> pois;
    private Map<String, Integer> countsByCategory; // UI filter panel için opsiyonel

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PoiSummaryDTO {
        private UUID poiId;
        private String name;
        private String category;
        private Double latitude;
        private Double longitude;
        private Double rating;
        private String priceLevel;
        private String externalId;
    }
}