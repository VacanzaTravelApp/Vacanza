package com.vacanza.backend.dto.request;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RouteHotelRequestDTO {
    private String hotelName;
    private String hotelExternalId;
    private String address;
    private Double latitude;
    private Double longitude;
    private String imageUrl;
    private String externalBookingUrl;
    private BigDecimal pricePerNight;
    private String currency;
    private Double rating;
    private String providerName;
}
