package com.vacanza.backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.math.BigDecimal;

@Data
public class ForecastItemDTO {
    private String name;
    
    @NotNull(message = "Amount cannot be null")
    private BigDecimal amount;
    
    @NotBlank(message = "Currency cannot be blank")
    private String currency;
}
