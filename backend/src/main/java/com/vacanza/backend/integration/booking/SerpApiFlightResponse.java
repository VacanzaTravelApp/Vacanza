package com.vacanza.backend.integration.booking;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.vacanza.backend.dto.response.TransportOptionDTO;
import lombok.Data;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Jackson POJOs for deserializing SerpApi Google Flights response.
 *
 * GET
 * /search.json?engine=google_flights&departure_id=...&arrival_id=...&outbound_date=...
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class SerpApiFlightResponse {

    @JsonProperty("best_flights")
    private List<FlightGroup> bestFlights;

    @JsonProperty("other_flights")
    private List<FlightGroup> otherFlights;

    @JsonProperty("price_insights")
    private PriceInsights priceInsights;

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class FlightGroup {
        private List<Flight> flights;
        private List<Layover> layovers;
        @JsonProperty("total_duration")
        private Integer totalDuration; // minutes
        private Integer price;
        private String type;
        @JsonProperty("airline_logo")
        private String airlineLogo;
        @JsonProperty("departure_token")
        private String departureToken;
        @JsonProperty("booking_token")
        private String bookingToken;
        @JsonProperty("carbon_emissions")
        private CarbonEmissions carbonEmissions;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Flight {
        @JsonProperty("departure_airport")
        private Airport departureAirport;
        @JsonProperty("arrival_airport")
        private Airport arrivalAirport;
        private Integer duration; // minutes
        private String airplane;
        private String airline;
        @JsonProperty("airline_logo")
        private String airlineLogo;
        @JsonProperty("travel_class")
        private String travelClass;
        @JsonProperty("flight_number")
        private String flightNumber;
        private String legroom;
        private List<String> extensions;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Airport {
        private String name;
        private String id;
        private String time; // "2025-07-01 08:30"
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Layover {
        private Integer duration; // minutes
        private String name;
        private String id;
        private Boolean overnight;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class CarbonEmissions {
        @JsonProperty("this_flight")
        private Integer thisFlight; // grams
        @JsonProperty("typical_for_this_route")
        private Integer typicalForThisRoute;
        @JsonProperty("difference_percent")
        private Integer differencePercent;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class PriceInsights {
        @JsonProperty("lowest_price")
        private Integer lowestPrice;
        @JsonProperty("price_level")
        private String priceLevel;
        @JsonProperty("typical_price_range")
        private List<Integer> typicalPriceRange;
    }

    // --- Mapping ---

    public static List<TransportOptionDTO> toTransportOptions(
            SerpApiFlightResponse response, String currency) {
        if (response == null) {
            return Collections.emptyList();
        }

        List<FlightGroup> allGroups = new ArrayList<>();
        if (response.getBestFlights() != null) {
            allGroups.addAll(response.getBestFlights());
        }
        if (response.getOtherFlights() != null) {
            allGroups.addAll(response.getOtherFlights());
        }

        if (allGroups.isEmpty()) {
            return Collections.emptyList();
        }

        return allGroups.stream()
                .filter(fg -> fg.getFlights() != null && !fg.getFlights().isEmpty())
                .filter(fg -> fg.getPrice() != null)
                .map(fg -> {
                    List<Flight> flights = fg.getFlights();
                    Flight firstFlight = flights.get(0);
                    Flight lastFlight = flights.get(flights.size() - 1);

                    String origin = firstFlight.getDepartureAirport() != null
                            ? firstFlight.getDepartureAirport().getId()
                            : "";
                    String destination = lastFlight.getArrivalAirport() != null
                            ? lastFlight.getArrivalAirport().getId()
                            : "";

                    String departureTime = firstFlight.getDepartureAirport() != null
                            ? firstFlight.getDepartureAirport().getTime()
                            : null;
                    String arrivalTime = lastFlight.getArrivalAirport() != null
                            ? lastFlight.getArrivalAirport().getTime()
                            : null;

                    // Carrier: use first flight's airline
                    String carrier = firstFlight.getAirline();
                    String airlineLogo = fg.getAirlineLogo() != null
                            ? fg.getAirlineLogo()
                            : firstFlight.getAirlineLogo();

                    // Duration: format total_duration (minutes) to "Xh Ym"
                    String duration = null;
                    if (fg.getTotalDuration() != null) {
                        int hours = fg.getTotalDuration() / 60;
                        int mins = fg.getTotalDuration() % 60;
                        duration = String.format("%dh %dm", hours, mins);
                    }

                    int stops = flights.size() - 1;

                    String flightNumber = firstFlight.getFlightNumber();
                    String travelClass = firstFlight.getTravelClass();

                    String bookingUrl = String.format(
                            "https://www.google.com/travel/flights?q=%s+to+%s",
                            origin, destination);

                    return TransportOptionDTO.builder()
                            .carrier(carrier)
                            .airlineLogo(airlineLogo)
                            .flightNumber(flightNumber)
                            .travelClass(travelClass)
                            .origin(origin)
                            .destination(destination)
                            .departureTime(departureTime)
                            .arrivalTime(arrivalTime)
                            .duration(duration)
                            .price(BigDecimal.valueOf(fg.getPrice()))
                            .currency(currency)
                            .stops(stops)
                            .bookingToken(fg.getDepartureToken())
                            .externalBookingUrl(bookingUrl)
                            .build();
                })
                .toList();
    }
}
