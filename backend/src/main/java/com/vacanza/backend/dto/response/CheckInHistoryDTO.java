package com.vacanza.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

/**
 * DTO for check-in history items displayed on the profile screen.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CheckInHistoryDTO {
    private UUID checkInId;
    private UUID poiId;
    private String poiName;
    private String category;
    private Instant checkedInAt;
    private Double latitude;
    private Double longitude;
}
