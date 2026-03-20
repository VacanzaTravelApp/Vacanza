package com.vacanza.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InteractionStatsResponseDTO {

    private long totalCount;
    private List<TypeCount> byType;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TypeCount {
        private String interactionType;
        private long count;
    }
}
