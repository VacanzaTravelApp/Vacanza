package com.vacanza.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PoiSearchMapboxStreamChunkDTO {

    @Builder.Default
    private String type = "chunk";

    /** Web filter key, e.g. restaurant, cafe. */
    private String uiCategory;

    private int chunkIndex;

    private List<PoiSearchInAreaResponseDTO.PoiSummaryDTO> pois;

    /** Running totals by coarse category string (Mapbox-side) after this chunk. */
    private Map<String, Integer> countsSoFar;
}
