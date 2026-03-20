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
    private String providerName;
    private String hotelName;
    private String hotelId;
    private String description;
    private String address;
    private BigDecimal price; // total stay price
    private BigDecimal pricePerNight; // average nightly rate
    private String currency;
    private Double rating;
    private Integer totalReviews;
    private Integer hotelClass;
    private String imageUrl;
    private Double latitude;
    private Double longitude;
    private String externalBookingUrl;
}
