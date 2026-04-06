package com.vacanza.backend.dto.request;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import lombok.Data;
import java.util.List;

@Data
public class ForecastRequestDTO {
    @NotBlank(message = "Target currency cannot be blank")
    private String targetCurrency;

    @NotEmpty(message = "Items list cannot be empty")
    @Valid
    private List<ForecastItemDTO> items;
}
