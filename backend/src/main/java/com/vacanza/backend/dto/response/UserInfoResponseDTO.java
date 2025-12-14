package com.vacanza.backend.dto.response;

import com.vacanza.backend.entity.enums.Budget;
import com.vacanza.backend.entity.enums.Gender;
import lombok.*;

import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserInfoResponseDTO {

    private UUID infoId;
    private UUID userId;

    private String firstName;
    private String middleName;
    private String lastName;
    private String preferredName;

    private String displayName;

    private String country;
    private LocalDate birthDate;
    private Gender gender;

    private Budget budget;

    private String profileImageUrl;

    private Instant joinDate;
}
