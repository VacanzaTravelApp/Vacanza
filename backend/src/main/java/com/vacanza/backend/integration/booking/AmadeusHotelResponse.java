package com.vacanza.backend.integration.booking;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.vacanza.backend.dto.response.AccommodationOptionDTO;
import lombok.Data;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;

/**
 * Jackson POJOs for deserializing Amadeus Hotel Offers API response.
 *
 * Amadeus flow:
 * 1. GET /v1/reference-data/locations/hotels/by-city?cityCode=XXX → hotel list
 * (hotelIds)
 * 2. GET /v3/shopping/hotel-offers?hotelIds=...&checkInDate=... → offers with
 * prices
 *
 * This class maps the Step 2 response.
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class AmadeusHotelResponse {

    private List<HotelOffer> data;

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class HotelOffer {
        private String type;
        private Hotel hotel;
        private boolean available;
        private List<Offer> offers;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Hotel {
        private String hotelId;
        private String name;
        private String cityCode;
        private Double rating;
        private Address address;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Address {
        private String countryCode;
        @JsonProperty("lines")
        private List<String> lines;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Offer {
        private String id;
        private Price price;
        private Room room;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Price {
        private String currency;
        private String total;
        private Variations variations;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Variations {
        private Average average;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Average {
        private String base;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Room {
        private TypeEstimated typeEstimated;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class TypeEstimated {
        private String category;
        private Integer beds;
        private String bedType;
    }

    /**
     * Separate POJO for step 1: hotel list by city.
     * GET /v1/reference-data/locations/hotels/by-city
     */
    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class HotelListResponse {
        private List<HotelEntry> data;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class HotelEntry {
        private String hotelId;
        private String name;
        private String iataCode;
    }

    // --- Mapping ---

    public static List<AccommodationOptionDTO> toAccommodationOptions(AmadeusHotelResponse response) {
        if (response == null || response.getData() == null) {
            return Collections.emptyList();
        }

        return response.getData().stream()
                .filter(ho -> ho.isAvailable() && ho.getOffers() != null && !ho.getOffers().isEmpty())
                .map(ho -> {
                    Hotel hotel = ho.getHotel();
                    Offer offer = ho.getOffers().get(0); // first (cheapest) offer

                    String addressStr = "";
                    if (hotel.getAddress() != null && hotel.getAddress().getLines() != null) {
                        addressStr = String.join(", ", hotel.getAddress().getLines());
                    }

                    BigDecimal price = BigDecimal.ZERO;
                    BigDecimal perNight = null;
                    String currency = "USD";
                    if (offer.getPrice() != null) {
                        price = new BigDecimal(offer.getPrice().getTotal());
                        currency = offer.getPrice().getCurrency();
                        if (offer.getPrice().getVariations() != null
                                && offer.getPrice().getVariations().getAverage() != null
                                && offer.getPrice().getVariations().getAverage().getBase() != null) {
                            perNight = new BigDecimal(offer.getPrice().getVariations().getAverage().getBase());
                        }
                    }

                    String bookingUrl = String.format(
                            "https://www.booking.com/searchresults.html?ss=%s",
                            hotel.getName() != null ? hotel.getName().replace(" ", "+") : "");

                    return AccommodationOptionDTO.builder()
                            .hotelName(hotel.getName())
                            .hotelId(hotel.getHotelId())
                            .address(addressStr)
                            .price(price)
                            .pricePerNight(perNight)
                            .currency(currency)
                            .rating(hotel.getRating())
                            .externalBookingUrl(bookingUrl)
                            .build();
                })
                .toList();
    }
}
