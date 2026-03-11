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
public class TransportOptionDTO {
    private String carrier;
    private String airlineLogo;
    private String flightNumber;
    private String travelClass;
    private String origin;
    private String destination;
    private String departureTime;
    private String arrivalTime;
    private String duration;
    private BigDecimal price;
    private String currency;
    private Integer stops;
    private String bookingToken;
    private String externalBookingUrl;
}
