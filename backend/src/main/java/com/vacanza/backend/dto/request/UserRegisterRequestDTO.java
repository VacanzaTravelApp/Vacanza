package com.vacanza.backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserRegisterRequestDTO {
    //duruma gore email eklenebilir

    @NotBlank(message = "First name is required")
    private String firstName;

    private String middleName;   // optional

    @NotBlank(message = "Last name is required")
    private String lastName;

    private String preferredName;  // optional
}

