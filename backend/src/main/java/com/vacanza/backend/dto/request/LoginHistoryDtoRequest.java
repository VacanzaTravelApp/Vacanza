package com.vacanza.backend.dto.request;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class LoginHistoryDtoRequest {
    private UUID loginId;
    private UUID userId;
    private String loginProvider;
    private Instant loginTime;
    private String ipAddress;
}
