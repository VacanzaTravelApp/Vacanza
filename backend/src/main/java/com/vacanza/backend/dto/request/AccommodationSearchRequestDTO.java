package com.vacanza.backend.dto.request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import com.vacanza.backend.entity.enums.SortCriteria;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AccommodationSearchRequestDTO {

    @NotBlank(message = "City code is required (e.g. IST, PAR, LON)")
    private String cityCode;

    @NotNull(message = "Check-in date is required")
    private LocalDate checkInDate;

    @NotNull(message = "Check-out date is required")
    private LocalDate checkOutDate;

    @Min(value = 1, message = "At least 1 adult is required")
    private int adults = 1;

    /** Maximum budget per night. Null means no budget limit. */
    private BigDecimal budget;

    private String currency = "USD";

    private SortCriteria sortBy;
}
