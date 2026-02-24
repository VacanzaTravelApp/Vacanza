package com.vacanza.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AccommodationOptionDTO {
    private String hotelName;
    private String hotelId;
    private String address;
    private BigDecimal price;
    private String currency;
    private Double rating;
    private String externalBookingUrl;
}
