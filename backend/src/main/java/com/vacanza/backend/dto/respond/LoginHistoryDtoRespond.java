package com.vacanza.backend.dto.respond;

import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoginHistoryDtoRespond {

    private UUID loginId;
    private UUID userId;
    private String loginProvider;
    private Instant loginTime;
    private String ipAddress;
}