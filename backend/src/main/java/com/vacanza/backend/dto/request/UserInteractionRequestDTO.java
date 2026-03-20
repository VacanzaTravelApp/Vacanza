package com.vacanza.backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserInteractionRequestDTO {

    @NotBlank(message = "interaction_type is required")
    private String interactionType;

    private UUID targetId;

    private Map<String, Object> metadata;
}
