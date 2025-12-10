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
//user auth response sayilabilir
public class UserLoginResponseDTO {

    private boolean authenticated;

    private UserInfo user;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserInfo {
        private UUID userId;
        private String email;
        private String name; //belki hitap icin kullanilir
        private String role;
        private boolean verified;
    }
}
