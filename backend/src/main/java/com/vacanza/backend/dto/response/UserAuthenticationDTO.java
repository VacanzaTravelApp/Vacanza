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
public class UserAuthenticationDTO {
//request parti yok cunku herhangi bir istek yok, backendden gelen bir cevap bu sadece

    private UUID userId;
    private String firebaseUid;

    private String email;
    private String role;

    private boolean verified;

    // user_info tablo kaydı varsa true
    // gerek olmayabilir
    private boolean profileCompleted;
}
