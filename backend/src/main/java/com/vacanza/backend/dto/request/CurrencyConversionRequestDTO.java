package com.vacanza.backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class CurrencyConversionRequestDTO {
    @NotNull(message = "Amount cannot be null")
    private BigDecimal amount;

    @NotBlank(message = "From currency cannot be blank")
    private String fromCurrency;

    @NotBlank(message = "To currency cannot be blank")
    private String toCurrency;
}
