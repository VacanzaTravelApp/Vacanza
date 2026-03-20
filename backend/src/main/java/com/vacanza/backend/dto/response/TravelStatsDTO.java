package com.vacanza.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

/**
 * DTO for user travel statistics displayed on the profile screen.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TravelStatsDTO {
    private long visitedPoisCount;
    private Instant lastVisitDate;
    private String lastVisitPoiName;
    private String favoriteCategory;
    private long distinctCategoriesCount;
}
