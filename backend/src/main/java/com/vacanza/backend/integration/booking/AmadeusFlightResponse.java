package com.vacanza.backend.integration.booking;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.vacanza.backend.dto.response.TransportOptionDTO;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;

/**
 * Jackson POJOs for deserializing Amadeus Flight Offers Search API response.
 *
 * GET
 * /v2/shopping/flight-offers?originLocationCode=...&destinationLocationCode=...
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class AmadeusFlightResponse {

    private List<FlightOffer> data;

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class FlightOffer {
        private String id;
        private String source;
        private List<Itinerary> itineraries;
        private Price price;
        private List<String> validatingAirlineCodes;
        private int numberOfBookableSeats;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Itinerary {
        private String duration;
        private List<Segment> segments;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Segment {
        private Location departure;
        private Location arrival;
        private String carrierCode;
        private String number;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Location {
        private String iataCode;
        private String at; // ISO 8601 datetime string
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Price {
        private String currency;
        private String total;
        private String grandTotal;
    }

    // --- Mapping ---

    public static List<TransportOptionDTO> toTransportOptions(AmadeusFlightResponse response) {
        if (response == null || response.getData() == null) {
            return Collections.emptyList();
        }

        return response.getData().stream()
                .filter(fo -> fo.getItineraries() != null && !fo.getItineraries().isEmpty())
                .map(fo -> {
                    Itinerary firstItinerary = fo.getItineraries().get(0);
                    List<Segment> segments = firstItinerary.getSegments();

                    Segment firstSegment = segments.get(0);
                    Segment lastSegment = segments.get(segments.size() - 1);

                    String carrier = fo.getValidatingAirlineCodes() != null
                            && !fo.getValidatingAirlineCodes().isEmpty()
                                    ? fo.getValidatingAirlineCodes().get(0)
                                    : firstSegment.getCarrierCode();

                    String origin = firstSegment.getDeparture().getIataCode();
                    String destination = lastSegment.getArrival().getIataCode();

                    LocalDateTime departureTime = LocalDateTime.parse(
                            firstSegment.getDeparture().getAt());
                    LocalDateTime arrivalTime = LocalDateTime.parse(
                            lastSegment.getArrival().getAt());

                    BigDecimal price = BigDecimal.ZERO;
                    String currency = "USD";
                    if (fo.getPrice() != null) {
                        String priceStr = fo.getPrice().getGrandTotal() != null
                                ? fo.getPrice().getGrandTotal()
                                : fo.getPrice().getTotal();
                        price = new BigDecimal(priceStr);
                        currency = fo.getPrice().getCurrency();
                    }

                    int stops = segments.size() - 1;

                    String bookingUrl = String.format(
                            "https://www.google.com/travel/flights?q=%s+to+%s",
                            origin, destination);

                    return TransportOptionDTO.builder()
                            .carrier(carrier)
                            .origin(origin)
                            .destination(destination)
                            .departureTime(departureTime)
                            .arrivalTime(arrivalTime)
                            .duration(firstItinerary.getDuration())
                            .price(price)
                            .currency(currency)
                            .stops(stops)
                            .externalBookingUrl(bookingUrl)
                            .build();
                })
                .toList();
    }
}
