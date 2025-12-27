package com.vacanza.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
//userinfo icin lazim olabilir
//backend register etmeyecek ama sync icin gerekli

public class UserRegisterResponseDTO {
    private boolean success;
    private String message;
    private UUID userId;
}

