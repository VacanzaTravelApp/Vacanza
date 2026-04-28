package com.vacanza.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PoiSearchMapboxStreamDoneDTO {

    @Builder.Default
    private String type = "done";

    private int totalDistinct;

    private Map<String, Integer> countsByCategory;
}
