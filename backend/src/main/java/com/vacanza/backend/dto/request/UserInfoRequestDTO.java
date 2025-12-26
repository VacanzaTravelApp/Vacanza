package com.vacanza.backend.dto.request;

import com.vacanza.backend.entity.enums.Budget;
import com.vacanza.backend.entity.enums.Gender;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
//hem profil olusturma hem update için ayni DTO kullanılabilsin diye optional
public class UserInfoRequestDTO {

    private String firstName;
    private String middleName;
    private String lastName;
    private String preferredName;

    private String country;
    private LocalDate birthDate;
    private Gender gender;

    private Budget budget;

    private String profileImageUrl;
}
