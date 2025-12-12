package com.vacanza.backend.dto.response;

import lombok.*;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
//ana ekranda kucuk profil kutucugu icin
public class UserSummaryDTO {

    private UUID userId;

    private String displayName;
    private String profileImageUrl;
}
