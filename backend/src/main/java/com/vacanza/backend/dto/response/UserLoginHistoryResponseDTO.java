package com.vacanza.backend.dto.response;

import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserLoginHistoryResponseDTO {

    private UUID loginId;
    private UUID userId;
    private String loginProvider;
    private Instant loginTime;
    private String ipAddress;
}