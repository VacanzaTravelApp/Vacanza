package com.vacanza.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

/**
 * Response DTO for GET /admin/users.
 * Returns user profile data for the admin user management table.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AdminUserDTO {

    private UserSummary user;
    private boolean authenticated;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class UserSummary {
        private UUID userId;
        private String email;
        private String displayName;
        private String role;
    }
}
