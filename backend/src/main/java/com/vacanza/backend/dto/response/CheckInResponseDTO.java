package com.vacanza.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CheckInResponseDTO {
    private UUID checkInId;
    private UUID poiId;
    private String poiName;
    private Instant checkedInAt;
    private String message;
    private boolean success;
}
