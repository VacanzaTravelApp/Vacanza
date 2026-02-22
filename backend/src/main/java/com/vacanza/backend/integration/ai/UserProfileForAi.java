package com.vacanza.backend.integration.ai;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.vacanza.backend.dto.response.UserInfoResponseDTO;
import lombok.Builder;
import lombok.Value;

/**
 * User profile for AI service (X-User-Profile header).
 * All user_info fields relevant for personalization.
 */
@Value
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class UserProfileForAi {
    String displayName;
    String firstName;
    String middleName;
    String lastName;
    String preferredName;
    String country;
    String birthDate;
    String gender;
    String budget;
    String profileImageUrl;
    String joinDate;

    public static UserProfileForAi from(UserInfoResponseDTO dto) {
        if (dto == null) return null;
        return UserProfileForAi.builder()
                .displayName(dto.getDisplayName())
                .firstName(dto.getFirstName())
                .middleName(dto.getMiddleName())
                .lastName(dto.getLastName())
                .preferredName(dto.getPreferredName())
                .country(dto.getCountry())
                .birthDate(dto.getBirthDate() != null ? dto.getBirthDate().toString() : null)
                .gender(dto.getGender() != null ? dto.getGender().name() : null)
                .budget(dto.getBudget() != null ? dto.getBudget().name() : null)
                .profileImageUrl(dto.getProfileImageUrl())
                .joinDate(dto.getJoinDate() != null ? dto.getJoinDate().toString() : null)
                .build();
    }
}
