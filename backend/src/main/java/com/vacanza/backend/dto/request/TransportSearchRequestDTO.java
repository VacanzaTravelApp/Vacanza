package com.vacanza.backend.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import com.vacanza.backend.entity.enums.SortCriteria;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TransportSearchRequestDTO {

    @NotBlank(message = "Origin is required (e.g. IST)")
    @Pattern(regexp = "^[A-Z]{3}$", message = "Origin must be a valid 3-letter IATA code")
    private String origin;

    @NotBlank(message = "Destination is required (e.g. PAR)")
    @Pattern(regexp = "^[A-Z]{3}$", message = "Destination must be a valid 3-letter IATA code")
    private String destination;

    @NotNull(message = "Departure date is required")
    private LocalDate departureDate;

    /** Null means one-way search. */
    private LocalDate returnDate;

    @Min(value = 1, message = "At least 1 adult is required")
    private int adults = 1;

    /** Maximum total budget. Null means no budget limit. */
    private BigDecimal budget;

    private String currency = "USD";

    private SortCriteria sortBy;
}
