package com.vacanza.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.*;

import java.math.BigDecimal;

@Embeddable
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RouteHotel {

    @Column(name = "hotel_name")
    private String hotelName;

    @Column(name = "hotel_external_id")
    private String hotelExternalId;

    @Column(name = "hotel_address")
    private String address;

    @Column(name = "hotel_latitude")
    private Double latitude;

    @Column(name = "hotel_longitude")
    private Double longitude;

    @Column(name = "hotel_image_url", length = 2048)
    private String imageUrl;

    @Column(name = "hotel_booking_url", length = 2048)
    private String externalBookingUrl;

    @Column(name = "hotel_price_per_night", precision = 10, scale = 2)
    private BigDecimal pricePerNight;

    @Column(name = "hotel_currency", length = 8)
    private String currency;

    @Column(name = "hotel_rating")
    private Double rating;

    @Column(name = "hotel_provider")
    private String providerName;
}
